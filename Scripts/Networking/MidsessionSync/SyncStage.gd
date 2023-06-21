extends Node
class_name SyncStage

signal began
signal completed

var peer_id: int = -1

var num_nodes_syncd = 0 : set = set_num_nodes_syncd
var total_num_nodes_to_sync = 0
var num_packets_sent = 0
var num_packets_to_incur_wait = 200
var seconds_to_wait_between_many_packets = 0.1
var start_time_ms = 0

func set_num_nodes_syncd(value: int) -> void:
	num_nodes_syncd = value
	if num_nodes_syncd >= total_num_nodes_to_sync:
		client_finished()

## Override this
func _nodes_to_sync() -> Array[Node]:
	return []

## Override this
## nodes is the result of [_get_nodes_to_sync]
func _sync_process(_nodes: Array[Node]) -> void:
	pass

## Override this
## Return the number of nodes sync'd for that batch
func _receive_sync_data(_data: PackedByteArray) -> int:
	return 1

## Override this
func _client_finished() -> void:
	pass

func nodes_to_sync() -> Array[Node]:
	return _nodes_to_sync()

func send_client_sync_data(data: PackedByteArray) -> void:
	num_packets_sent += 1
	if num_packets_sent % num_packets_to_incur_wait == 0:
		print_verbose("Pausing for %s seconds between sending %s packets" % [seconds_to_wait_between_many_packets, num_packets_to_incur_wait])
		await get_tree().create_timer(seconds_to_wait_between_many_packets, true).timeout
	notify_client_sync_data.rpc_id(peer_id, data)

@rpc("authority", "reliable")
func notify_client_sync_data(data: PackedByteArray) -> void:
	receive_sync_data(data)

func receive_sync_data(data: PackedByteArray) -> void:
	var nodes_syncd = _receive_sync_data(data)
	num_nodes_syncd += nodes_syncd

func begin(p_id: int) -> void:
	start_time_ms = Time.get_ticks_msec()
	began.emit()
	peer_id = p_id
	print_verbose("------Begin Server %s for Peer %s------" % [name, peer_id])
	
	var nodes = nodes_to_sync()
	total_num_nodes_to_sync = nodes.size()
	notify_client_num_nodes_to_complete_sync.rpc_id(peer_id, total_num_nodes_to_sync)
	sync_process(nodes)

@rpc("authority", "reliable")
func notify_client_num_nodes_to_complete_sync(num_nodes: int) -> void:
	total_num_nodes_to_sync = num_nodes
	if total_num_nodes_to_sync == 0:
		client_finished()

func sync_process(nodes: Array[Node]) -> void:
	_sync_process(nodes)

func client_finished():
	_client_finished()
	print_verbose("Client %s finished %s | Notifying server" % [multiplayer.get_unique_id(), name])
	notify_server_stage_finished.rpc_id(GameState.SERVER_ID)
	completed.emit()
	
@rpc("any_peer", "reliable")
func notify_server_stage_finished() -> void:
	finish()

func finish():
	completed.emit()
	print_verbose("------End Server %s for Peer %s in %d ms------" % [name, peer_id, Time.get_ticks_msec() - start_time_ms])
