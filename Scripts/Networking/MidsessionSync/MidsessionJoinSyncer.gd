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
	
	var peer_id: int = -1
	var current_stage = 0
	var finished = false
	var pipeline : Array[SyncStage] = []
	
	var stage : SyncStage : get = get_stage
	
	func get_stage() -> SyncStage:
		return pipeline[current_stage]
	
	func _init(to_sync_peer_id: int) -> void:
		peer_id = to_sync_peer_id
		
		# Could be configurable in the future if necessary
		pipeline = [
			LayoutSyncStage.new(),
			NetworkedNodeSyncStage.new(),
			PlayerSyncStage.new(),
		]
		
		for sync_stage in pipeline:
			add_child(sync_stage)
		
		name = "SyncPipeline_" + str(peer_id)
	
	func advance() -> void:
		current_stage += 1
	
	func start() -> void:
		while current_stage < pipeline.size():
			stage.begin.call_deferred(peer_id)
			await stage.completed
			advance()
		
		finished = true
	
const FAIL_SAFE_TIMER = 10.0
var syncing = {}

var is_synced : bool : get = get_is_synced

func get_is_synced() -> bool:
	return syncing.size() == 0

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
		await pipeline.stage.completed
		sync_stage_complete.emit() # Server-side, doesn't do much
		notify_peer_sync_stage_complete.rpc_id(peer_id, pipeline.current_stage)
	
	# These probably deserve their own stages too
	sync_game_state.rpc_id(peer_id, GameState.get_sync_state().data)
	NetworkingUtils.sync_id.rpc_id(peer_id, NetworkingUtils.ID)
	
	finish_sync(peer_id)
	print("Finished Sync for Peer %s in %d ms" % [peer_id, Time.get_ticks_msec() - start_time_ms])

func start_fail_safe_unpause_timer(peer_id: int) -> void:	
	await get_tree().create_timer(FAIL_SAFE_TIMER, true).timeout
	
	if get_tree().paused and syncing.get(peer_id) != null and not syncing[peer_id].finished:
		print_debug("Server waited %d seconds for the client to sync, it never sent the message, disconnecting %s" % [FAIL_SAFE_TIMER, peer_id])
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		if syncing.size() == 0 or syncing.all(func(pipeline): return pipeline.finished):
			print_debug("Fallback unpausing for everyone as the server is no longer syncing")
			unpause_for_players.rpc()

func begin_sync(peer_id: int, needs_sync: bool) -> void:
	if not needs_sync:
		notify_client_sync_complete.rpc_id(peer_id)
		return
	
	pause_for_players.rpc()
	start_fail_safe_unpause_timer(peer_id)
	start_sync_pipeline_for_peer.rpc_id(peer_id)
	iterate_sync_stages(peer_id)

func finish_sync(peer_id: int) -> void:
	sync_complete.emit()
	notify_client_sync_complete.rpc_id(peer_id)
	unpause_for_players.rpc()

@rpc("call_local", "reliable")
func pause_for_players():
	GameState.hud.display_notification("A Player is joining...")
	get_tree().paused = true

@rpc("call_local", "reliable")
func unpause_for_players():
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
