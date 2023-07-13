extends Node
class_name SyncStage

signal began
signal completed

var peer_id: int = -1

var num_nodes_syncd = 0 : set = set_num_nodes_syncd
var total_num_nodes_to_sync = 0
var num_packets_sent = 0
var num_packets_to_incur_wait : int = 200
var seconds_to_wait_between_many_packets = 0.1
var start_time_ms = 0
var fail_safe_timer_seconds = 10.0

var total_bytes_sent = 0
var total_bytes_received = 0
var successful = false
var failed = false
var batch_size : int = 0 : set = set_batch_size

func _init(stage_name: String, syncing_peer_id: int) -> void:
	name = stage_name + "_" + str(syncing_peer_id)
	peer_id = syncing_peer_id

func set_batch_size(value: int) -> void:
	batch_size = value
	@warning_ignore("integer_division")
	num_packets_to_incur_wait = 2 # Completely arbitrary number

func set_num_nodes_syncd(value: int) -> void:
	num_nodes_syncd = value
	if num_nodes_syncd >= total_num_nodes_to_sync:
		client_finished()

## Override this
func _nodes_to_sync() -> Array[Node]:
	return []

## Override this
func _write_node(_node: Node, _writer: ByteWriter) -> void:
	pass

## Override this
func _read_node(_reader: ByteReader) -> void:
	pass

## Override this
## nodes is the result of [_get_nodes_to_sync]
func _sync_process(nodes: Array[Node]) -> void:
	for node in nodes:
		var writer = ByteWriter.new()
		_write_node(node, writer)
		await send_client_sync_data(writer.data)

## Override this
## Return the number of nodes sync'd for that batch
func _receive_sync_data(data: PackedByteArray) -> int:
	var reader = ByteReader.new(data)
	_read_node(reader)
	return 1

## Override this
func _client_begin() -> void:
	pass

## Override this
func _client_finished() -> void:
	pass

func _ensure_sync_nodes_are_ready() -> void:
	var nodes = _nodes_to_sync()
	for node in nodes:
		if not node.is_node_ready():
			print("[%s] Node: %s isn't ready, waiting for ready signal..." % [name, node.name])
			await node.ready
			print("[%s] Node: %s is now ready, progressing" % [name, node.name])

func ensure_sync_nodes_are_ready() -> void:
	await _ensure_sync_nodes_are_ready()
	await get_tree().physics_frame
	await get_tree().physics_frame

func nodes_to_sync() -> Array[Node]:
	return _nodes_to_sync()

func send_client_sync_data(data: PackedByteArray) -> void:
	num_packets_sent += 1
	if num_packets_sent % num_packets_to_incur_wait == 0:
		print_verbose("Pausing for %s seconds between sending %s packets" % [seconds_to_wait_between_many_packets, num_packets_to_incur_wait])
		await get_tree().create_timer(seconds_to_wait_between_many_packets, true).timeout
	total_bytes_sent += data.size()
	notify_client_sync_data.rpc_id(peer_id, data)

@rpc("authority", "reliable")
func notify_client_sync_data(data: PackedByteArray) -> void:
	receive_sync_data(data)

func receive_sync_data(data: PackedByteArray) -> void:
	total_bytes_received += data.size()
	if batch_size > 0:
		var reader = ByteReader.new(data)
		var num_nodes = reader.read_int()
		
		for _data in range(num_nodes):
			_read_node(reader)
		
		num_nodes_syncd += num_nodes
	else:
		var nodes_syncd = _receive_sync_data(data)
		num_nodes_syncd += nodes_syncd

func begin(p_id: int) -> void:
	start_time_ms = Time.get_ticks_msec()
	began.emit()
	peer_id = p_id
	
	var nodes = nodes_to_sync()
	total_num_nodes_to_sync = nodes.size()
	notify_client_num_nodes_to_complete_sync.rpc_id(peer_id, total_num_nodes_to_sync)
	
	start_fail_safe_timer()
	if batch_size > 0:
		batched_sync_process(nodes)
	else:
		sync_process(nodes)

@rpc("authority", "reliable")
func notify_client_num_nodes_to_complete_sync(num_nodes: int) -> void:
	start_time_ms = Time.get_ticks_msec()
	total_num_nodes_to_sync = num_nodes
	if total_num_nodes_to_sync == 0:
		client_finished()
	else:
		client_begin()

func batched_sync_process(nodes: Array[Node]) -> void:
	var iterations = 1 # Start at 1 so we don't immediately send a batch with 1
	var writer = ByteWriter.new()
	var remainder_batch_size = nodes.size() % batch_size
	
	# There is enough for a full batch in the first pass
	if nodes.size() >= batch_size:
		writer.write_int(batch_size)
	else:
		writer.write_int(remainder_batch_size)
	
	# If I knew how to just write a dictionary with different key/val types
	# This could get simplified greatly
	# [PackedByteArray.encode_var] doesn't make a lot of sense to me yet, but that would be how
	for node in nodes as Array[Node]:
		_write_node(node, writer)
		
		if iterations % batch_size == 0:
			await send_client_sync_data(writer.data)
			writer = ByteWriter.new()
			
			# Is there still enough for a full batch in the next pass
			if nodes.size() - iterations >= batch_size:
				writer.write_int(batch_size)
			else:
				remainder_batch_size = nodes.size() % batch_size
				writer.write_int(remainder_batch_size)
			#print("Sending batch of ", batch_size)
		
		iterations += 1
	
	# The leftover nodes that didnt get put into a full batch
	if remainder_batch_size != 0:
		#print("remainder_batch_size of ", remainder_batch_size)
		writer.write_int(remainder_batch_size)
		send_client_sync_data(writer.data)

func sync_process(nodes: Array[Node]) -> void:
	_sync_process(nodes)

func client_begin() -> void:
	_client_begin()

func client_finished() -> void:
	_client_finished()
	await _ensure_sync_nodes_are_ready()
	print_verbose("[Client %s Peer %s] <End> | %d ms | Received %d bytes------" % [name, peer_id, Time.get_ticks_msec() - start_time_ms, total_bytes_received])
	notify_server_stage_finished.rpc_id(GameState.SERVER_ID)
	successful = true
	completed.emit()
	
@rpc("any_peer", "reliable")
func notify_server_stage_finished() -> void:
	finish()

func finish():
	successful = true
	completed.emit()
	print("[Server %s Peer %s] <End> | %d ms | Sent %d bytes------" % [name, peer_id, Time.get_ticks_msec() - start_time_ms, total_bytes_sent])

func start_fail_safe_timer() -> void:
	await get_tree().create_timer(fail_safe_timer_seconds, true).timeout
	if not successful:
		print("[Server %s Peer %s] <Fail> | %d ms | Sent %d bytes------" % [name, peer_id, Time.get_ticks_msec() - start_time_ms, total_bytes_sent])
		failed = true
		completed.emit()
