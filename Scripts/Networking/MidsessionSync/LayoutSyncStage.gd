extends SyncStage
class_name LayoutSyncStage

const LAYOUT_BATCH_SIZE = 50

func _ready():
	name = "LayoutSyncStage"
	batch_size = LAYOUT_BATCH_SIZE

func _nodes_to_sync() -> Array[Node]:
	return get_tree().get_nodes_in_group("runtime_spawned")

func _write_node(node: Node, writer: ByteWriter) -> void:
	writer.write_str(node.scene_file_path)
	writer.write_path_to(node.get_parent())
	
	writer.write_str(node.name)
	writer.write_vector3(node.global_position)
	writer.write_vector3(node.global_rotation)

func _read_node(reader: ByteReader) -> void:
	var scene_path = reader.read_str()
	var parent_path_to = reader.read_path_to()
	
	var node_name = reader.read_str()
	var global_pos = reader.read_vector3()
	var global_rot = reader.read_vector3()
	var spawned_node = NetworkingUtils.spawn_node_by_scene_path(scene_path, get_node(parent_path_to))
	spawned_node.name = node_name
	spawned_node.global_position = global_pos
	spawned_node.global_rotation = global_rot
