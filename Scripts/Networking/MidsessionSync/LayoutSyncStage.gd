extends SyncStage
class_name LayoutSyncStage

const LAYOUT_BATCH_SIZE = 20

func _ready():
	name = "LayoutSyncStage"
	num_packets_to_incur_wait = LAYOUT_BATCH_SIZE

func _nodes_to_sync() -> Array[Node]:
	return get_tree().get_nodes_in_group("changed_static_bodies")

func _sync_process(nodes: Array[Node]) -> void:
	var iterations = 0
	var writer = ByteWriter.new()
	
	for static_body in nodes as Array[StaticBody3D]:
		writer.write_path_to(static_body.owner)
		writer.write_vector3(static_body.owner.global_position)
		writer.write_vector3(static_body.owner.global_rotation)
		if iterations % LAYOUT_BATCH_SIZE == 0:
			send_client_sync_data(writer.data)
			writer = ByteWriter.new()
		iterations += 1

func _receive_sync_data(data: PackedByteArray) -> int:
	var reader = ByteReader.new(data)
	for _data in range(LAYOUT_BATCH_SIZE):
		var path_to = reader.read_path_to()
		var global_pos = reader.read_vector3()
		var global_rot = reader.read_vector3()
		var node = get_node(path_to)
		node.global_position = global_pos
		node.global_rotation = global_rot
	
	return LAYOUT_BATCH_SIZE
