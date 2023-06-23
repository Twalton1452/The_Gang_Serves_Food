@icon("res://Icons/wifi.svg")
extends Node

## Autoloaded

signal sync_stage_complete
signal sync_complete
## Client only, emitted after the sync has completed
## waits a couple frames then initiates the queued up RPCs
signal accept_rpcs


## Class for holding the SyncStages so the server can create multiple stateful Stages
## Necessary to sync more than 1 client
class SyncPipeline extends Node:
	signal changed
	
	var peer_id: int = -1
	var current_stage = 0 : set = set_current_stage
	var finished = false
	var aborted = false
	var pipeline : Array[SyncStage] = []
	var total_bytes_sent : int = 0
	
	var stage : SyncStage : get = get_stage
	
	func set_current_stage(value: int) -> void:
		current_stage = value
		if current_stage >= pipeline.size():
			finished = true
	
	func get_stage() -> SyncStage:
		return pipeline[current_stage]
	
	func _init(to_sync_peer_id: int) -> void:
		peer_id = to_sync_peer_id
		
		# Could be configurable in the future if necessary
		pipeline = [
			LayoutSyncStage.new(),
			NetworkedNodeSpawnStage.new(),
			NetworkedNodeSyncStage.new(),
			PlayerSyncStage.new(),
		]
		
		for sync_stage in pipeline:
			sync_stage.peer_id = to_sync_peer_id
			add_child(sync_stage)
		
		name = "SyncPipeline_" + str(peer_id)
	
	func advance() -> void:
		total_bytes_sent += stage.total_bytes_sent
		current_stage += 1
		changed.emit()
	
	func fail() -> void:
		aborted = true
		changed.emit()
	
	func start() -> void:
		while not aborted and current_stage < pipeline.size():
			stage.begin.call_deferred(peer_id)
			await stage.completed
			if stage.failed:
				fail()
				return
			
			advance()
	
const FAIL_SAFE_TIMER = 10.0
var syncing = {}

var is_synced : bool : get = get_is_synced

func get_is_synced() -> bool:
	return syncing.size() == 0 or syncing.values().all(func(pipeline): return pipeline.finished or pipeline.aborted)

func cleanup_disconnected_player(peer_id: int) -> void:
	erase_pipeline_for(peer_id)

func create_pipeline_for(peer_id: int) -> SyncPipeline:
	var pipeline = SyncPipeline.new(peer_id)
	add_child(pipeline)
	syncing[peer_id] = pipeline
	return pipeline

func erase_pipeline_for(peer_id: int) -> void:
	if syncing.get(peer_id) != null and not syncing[peer_id].is_queued_for_deletion():
		syncing[peer_id].queue_free()
	syncing.erase(peer_id)

## needs_sync = false when the level is reloaded while players are connected
func iterate_sync_stages(peer_id: int) -> void:
	var start_time_ms = Time.get_ticks_msec()
	var pipeline : SyncPipeline = create_pipeline_for(peer_id)
	pipeline.start()
	
	while not pipeline.finished:
		await pipeline.changed
		
		if pipeline.aborted:
			var elapsed_time_to_fail = Time.get_ticks_msec() - pipeline.stage.start_time_ms
			print_debug("%s was aborted during stage %s | Time to fail: %d ms" % \
				[pipeline.name, pipeline.stage.name, elapsed_time_to_fail])
			handle_aborted_sync(peer_id)
			return
		
		sync_stage_complete.emit() # Server-side, doesn't do much
		notify_peer_sync_stage_complete.rpc_id(peer_id, pipeline.current_stage)
	
	# These probably deserve their own stages too
	sync_game_state.rpc_id(peer_id, GameState.get_sync_state().data)
	NetworkingUtils.sync_id.rpc_id(peer_id, NetworkingUtils.ID)
	
	finish_sync(peer_id)
	print("======Finished Sync for Peer %s | %d ms | %d bytes sent======" % [peer_id, Time.get_ticks_msec() - start_time_ms, pipeline.total_bytes_sent])

func begin_sync(peer_id: int, needs_sync: bool) -> void:
	if not needs_sync:
		notify_client_sync_complete.rpc_id(peer_id)
		return
	
	pause_for_players.rpc()
	start_sync_pipeline_for_peer.rpc_id(peer_id)
	iterate_sync_stages(peer_id)

func finish_sync(peer_id: int) -> void:
	sync_complete.emit()
	notify_client_sync_complete.rpc_id(peer_id)
	unpause_for_players.rpc()

func handle_aborted_sync(peer_id: int) -> void:
	if not get_tree().paused:
		return
	
	print_debug("Pipeline failed to sync for Peer %s | Disconnecting them..." % [peer_id])
	multiplayer.multiplayer_peer.disconnect_peer(peer_id)
	
	# A different peer is still syncing, don't unpause for everyone else yet
	if not is_synced:
		return
	
	print_debug("Fallback unpausing for everyone as the server is no longer syncing")
	for peer in multiplayer.get_peers():
		if peer == peer_id:
			continue
		unpause_for_player.rpc_id(peer)
	unpause_for_player()

@rpc("call_local", "reliable")
func pause_for_players():
	GameState.hud.display_notification("A Player is joining...")
	get_tree().paused = true

@rpc("call_local", "reliable")
func unpause_for_players():
	GameState.hud.hide_notification()
	get_tree().paused = false

@rpc("reliable")
func unpause_for_player():
	GameState.hud.hide_notification()
	get_tree().paused = false

@rpc("authority", "reliable")
func sync_game_state(sync_state: PackedByteArray):
	var sync_state_reader : ByteReader = ByteReader.new(sync_state)
	GameState.set_sync_state(sync_state_reader)

@rpc("authority", "reliable")
func notify_peer_sync_stage_complete(sync_stage: int) -> void:
	sync_stage_complete.emit()
	syncing[multiplayer.get_unique_id()].current_stage = sync_stage

## Used to emit sync_complete signal on the client side
## NetworkedNode3D's are dependent on this signal for their process
@rpc("authority", "reliable")
func notify_client_sync_complete() -> void:
	sync_complete.emit()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	accept_rpcs.emit()

## Need to create the pipeline on the client side 
## This enables the client to have access to the RPC calls embedded within the SyncStages
@rpc("authority", "reliable")
func start_sync_pipeline_for_peer() -> void:
	create_pipeline_for(multiplayer.get_unique_id())
