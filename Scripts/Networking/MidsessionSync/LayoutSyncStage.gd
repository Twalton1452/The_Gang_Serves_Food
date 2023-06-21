extends SyncStage
class_name LayoutSyncStage

const LAYOUT_BATCH_SIZE = 10

func _ready():
	name = "LayoutSyncStage"
	num_packets_to_incur_wait = LAYOUT_BATCH_SIZE

func _nodes_to_sync() -> Array[Node]:
	return get_tree().get_nodes_in_group("runtime_spawned")

func _sync_process(nodes: Array[Node]) -> void:
	var iterations = 1 # Start at 1 so we don't immediately send a batch with 1
	var writer = ByteWriter.new()
	var remainder_batch_size = nodes.size() % LAYOUT_BATCH_SIZE
	
	# There is enough for a full batch in the first pass
	if nodes.size() >= LAYOUT_BATCH_SIZE:
		writer.write_int(LAYOUT_BATCH_SIZE)
	else:
		writer.write_int(remainder_batch_size)
	
	# If I knew how to just write a dictionary with different key/val types
	# This could get simplified greatly
	# [PackedByteArray.encode_var] doesn't make a lot of sense to me yet, but that would be how
	for node in nodes as Array[Node]:
		writer.write_str(node.scene_file_path)
		writer.write_path_to(node.get_parent())
		
		writer.write_str(node.name)
		writer.write_vector3(node.global_position)
		writer.write_vector3(node.global_rotation)
		
		if iterations % LAYOUT_BATCH_SIZE == 0:
			await send_client_sync_data(writer.data)
			writer = ByteWriter.new()
			
			# Is there still enough for a full batch in the next pass
			if nodes.size() - iterations >= LAYOUT_BATCH_SIZE:
				writer.write_int(LAYOUT_BATCH_SIZE)
			else:
				remainder_batch_size = nodes.size() % LAYOUT_BATCH_SIZE
				writer.write_int(remainder_batch_size)
			#print("Sending batch of ", LAYOUT_BATCH_SIZE)
		
		iterations += 1
	
	# The leftover nodes that didnt get put into a full batch
	if remainder_batch_size != 0:
		#print("remainder_batch_size of ", remainder_batch_size)
		writer.write_int(remainder_batch_size)
		send_client_sync_data(writer.data)

func _receive_sync_data(data: PackedByteArray) -> int:
	var reader = ByteReader.new(data)
	var batch_size = reader.read_int()
	
	for _data in range(batch_size):
		var scene_path = reader.read_str()
		var parent_path_to = reader.read_path_to()
		
		var node_name = reader.read_str()
		var global_pos = reader.read_vector3()
		var global_rot = reader.read_vector3()
		var spawned_node = NetworkingUtils.spawn_node_by_scene_path(scene_path, get_node(parent_path_to))
		spawned_node.name = node_name
		spawned_node.global_position = global_pos
		spawned_node.global_rotation = global_rot
	
	return batch_size
