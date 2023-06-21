@icon("res://Icons/wifi.svg")
extends Node

## Autoloaded

signal sync_stage_complete
signal sync_complete
## Client only, emitted after the sync has completed
## waits a couple frames then initiates the queued up RPCs
signal accept_rpcs

var current_sync_stage = 0
# TODO: Recreate pipeline per peer connecting because they hold important state
var SYNC_PIPELINE : Array[SyncStage] = [
	LayoutSyncStage.new(),
	NetworkedNodeSyncStage.new(),
	PlayerSyncStage.new(),
]

const FAIL_SAFE_TIMER = 10.0
var syncing = {}

var is_synced = false : get = get_is_synced

func _ready():
	for stage in SYNC_PIPELINE:
		add_child(stage)

func get_is_synced() -> bool:
	return current_sync_stage >= SYNC_PIPELINE.size()

## needs_sync = false when the level is reloaded while players are connected
func iterate_sync_stages(peer_id: int, needs_sync: bool) -> void:
	var start_time_ms = Time.get_ticks_msec()
	
	while current_sync_stage < SYNC_PIPELINE.size():
		SYNC_PIPELINE[current_sync_stage].begin.call_deferred(peer_id, needs_sync)
		await SYNC_PIPELINE[current_sync_stage].completed
		sync_stage_complete.emit()
		notify_peer_sync_stage_complete.rpc_id(peer_id, current_sync_stage)
		current_sync_stage += 1
	
	# These probably deserve their own stages too
	sync_game_state.rpc_id(peer_id, GameState.get_sync_state().data)
	NetworkingUtils.sync_id.rpc_id(peer_id, NetworkingUtils.ID)
	
	finish_sync(peer_id, needs_sync)
	print("Finished Sync for Peer %s in %d ms" % [peer_id, Time.get_ticks_msec() - start_time_ms])

func start_fail_safe_unpause_timer(peer_id: int) -> void:
	syncing[peer_id] = true
	
	await get_tree().create_timer(FAIL_SAFE_TIMER, true).timeout
	if get_tree().paused and syncing[peer_id]:
		syncing[peer_id] = false
		print_debug("Server waited %d seconds for the client to sync, it never sent the message, disconnecting %s" % [FAIL_SAFE_TIMER, peer_id])
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		if syncing.values().all(func(is_syncing): return not is_syncing):
			print_debug("Fallback unpausing for everyone as the server is no longer syncing")
			unpause_for_players.rpc(peer_id)

func begin_sync(peer_id: int, needs_sync: bool) -> void:
	if not needs_sync:
		notify_client_sync_complete.rpc_id(peer_id)
		return
	is_synced = false
	
	pause_for_players.rpc()
	start_fail_safe_unpause_timer(peer_id)
	
	iterate_sync_stages(peer_id, needs_sync)

func finish_sync(peer_id: int, _needs_sync: bool) -> void:
	is_synced = true
	sync_complete.emit()
	notify_client_sync_complete.rpc_id(peer_id)
	unpause_for_players.rpc(peer_id)

@rpc("call_local", "reliable")
func pause_for_players():
	GameState.hud.display_notification("A Player is joining...")
	get_tree().paused = true

@rpc("call_local", "reliable")
func unpause_for_players(unpaused_peer_id: int):
	GameState.hud.hide_notification()
	syncing[unpaused_peer_id] = false
	get_tree().paused = false

@rpc("authority", "reliable")
func sync_game_state(sync_state: PackedByteArray):
	var sync_state_reader : ByteReader = ByteReader.new(sync_state)
	GameState.set_sync_state(sync_state_reader)

@rpc("authority", "reliable")
func notify_peer_sync_stage_complete(sync_stage: int) -> void:
	sync_stage_complete.emit()
	current_sync_stage = sync_stage

## Used to emit sync_complete signal on the client side
## NetworkedNode3D's are dependent on this signal for their process
@rpc("authority", "reliable")
func notify_client_sync_complete() -> void:
	current_sync_stage = SYNC_PIPELINE.size()
	is_synced = true
	sync_complete.emit()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	accept_rpcs.emit()
