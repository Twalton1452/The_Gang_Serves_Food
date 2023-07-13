extends SyncStage
class_name LayoutSyncStage

const LAYOUT_BATCH_SIZE = 50

func _ready():
	batch_size = LAYOUT_BATCH_SIZE

func _nodes_to_sync() -> Array[Node]:
	return get_tree().get_nodes_in_group(NetworkedGrouperNode3D.GROUP_NAME)

## Each Write is for a Parent Node's children
func _write_node(node: Node, writer: ByteWriter) -> void:
	var sync_nodes : Array[Node] = (node as NetworkedGrouperNode3D).nodes
	
	writer.write_path_to(node)
	writer.write_int(sync_nodes.size())
	for sync_node in sync_nodes:
		writer.write_str(sync_node.name)
		writer.write_str(sync_node.scene_file_path)
		writer.write_vector3(sync_node.global_position)
		writer.write_vector3(sync_node.global_rotation)
		get_spawn_sync_data_for(sync_node, writer)

## Each Read is for a parent Node's children
func _read_node(reader: ByteReader) -> void:
	var parent_path = reader.read_path_to()
	var num_nodes = reader.read_int()
	
	var grouper_node : NetworkedGrouperNode3D = get_node(parent_path)
	var to_delete_nodes : Array[Node] = grouper_node.nodes
	
	for _i in range(num_nodes):
		var node_name = reader.read_str()
		var spawnable_scene_path = reader.read_str()
		var global_pos = reader.read_vector3()
		var global_rot = reader.read_vector3()
		
		var node : Node = grouper_node.get_node_or_null(node_name)
		if node == null:
			node = NetworkingUtils.spawn_node_by_scene_path(spawnable_scene_path, grouper_node)
		elif to_delete_nodes.size() > 0:
			var index = to_delete_nodes.find(node)
			if index != -1:
				to_delete_nodes.remove_at(index)
		
		set_spawn_sync_data_for(node, reader)
		node.set_name.call_deferred(node_name)
		node.global_position = global_pos
		node.global_rotation = global_rot
	
	for to_delete in to_delete_nodes:
		to_delete.queue_free()


## Get the spawn sync data of the node and all of its children
## use [set_spawn_sync_data_for] to set the data
## We need the name and id information of the child nodes to stay in sync between server/client
func get_spawn_sync_data_for(node: Node, writer: ByteWriter) -> void:
	var net_node : NetworkedNode3D = node.get_node_or_null(NetworkingUtils.NETWORKED_NODE_3D)
	if net_node != null and not net_node.p_node is Holdable:
		writer.append_array(net_node.get_spawnable_sync_state().data)
	get_spawn_sync_data_for_children_of(node, writer)

## Recursively get the spawn sync data of all the children for a particular Node
func get_spawn_sync_data_for_children_of(node: Node, writer: ByteWriter) -> void:
	for child in node.get_children():
		var child_net_node : NetworkedNode3D = child.get_node_or_null(NetworkingUtils.NETWORKED_NODE_3D)
		if child_net_node != null and not child_net_node.p_node is Holdable:
			writer.append_array(child_net_node.get_spawnable_sync_state().data)
		get_spawn_sync_data_for_children_of(child, writer)

## Set the spawn sync data of the node and all of its children
## use [get_spawn_sync_data_for] to generate the data
## We need the name and id information of the child nodes to stay in sync between server/client
func set_spawn_sync_data_for(node: Node, reader: ByteReader) -> void:
	var net_node : NetworkedNode3D = node.get_node_or_null(NetworkingUtils.NETWORKED_NODE_3D)
	if net_node != null and not net_node.p_node is Holdable:
		net_node.set_spawnable_sync_state(reader)
	
	set_spawn_sync_data_for_children_of(node, reader)

## Recursively set the spawn sync data of all the children for a particular Node
## use [get_spawn_sync_data_for_children_of] to generate the data
func set_spawn_sync_data_for_children_of(node: Node, reader: ByteReader) -> void:
	for child in node.get_children():
		var child_net_node : NetworkedNode3D = child.get_node_or_null(NetworkingUtils.NETWORKED_NODE_3D)
		if child_net_node != null and not child_net_node.p_node is Holdable:
			child_net_node.set_spawnable_sync_state(reader)
		set_spawn_sync_data_for_children_of(child, reader)
