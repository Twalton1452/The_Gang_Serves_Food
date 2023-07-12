extends SyncStage
class_name LayoutSyncStage

const LAYOUT_BATCH_SIZE = 50

func _ready():
	batch_size = LAYOUT_BATCH_SIZE

func _nodes_to_sync() -> Array[Node]:
	return get_tree().get_nodes_in_group(NetworkedGrouperNode3D.GROUP_NAME)

func _client_begin() -> void:
	# Reset the individual grouper nodes IDs before spawning
	for grouper in _nodes_to_sync() as Array[NetworkedGrouperNode3D]:
		grouper.ID = 0

func get_net_nodes_attached_to(node: Node) -> Array[Node]:
	return node.find_children(NetworkingUtils.NETWORKED_NODE_3D)

## Each Write is for a Grouper Node and its' children
func _write_node(node: Node, writer: ByteWriter) -> void:
	var grouper_node : NetworkedGrouperNode3D = node
	var sync_nodes : Array[Node] = grouper_node.nodes
	
	writer.write_path_to(grouper_node)
	writer.write_int(sync_nodes.size())
	writer.write_big_int(grouper_node.ID)
	for sync_node in sync_nodes:
		writer.write_str(sync_node.name)
		writer.write_str(sync_node.scene_file_path)
		writer.write_vector3(sync_node.global_position)
		writer.write_vector3(sync_node.global_rotation)
		
		var net_nodes_attached = get_net_nodes_attached_to(sync_node)
		writer.write_int(net_nodes_attached.size())
		for net_node in net_nodes_attached as Array[NetworkedNode3D]:
			writer.write_big_int(net_node.networked_id)
			writer.write_vector3(net_node.p_node.global_position)
			writer.write_vector3(net_node.p_node.global_rotation)
#			writer.write_int(net_node.SCENE_ID)
			writer.write_str(net_node.p_node.scene_file_path)
			writer.write_relative_path_to(net_node.p_node, sync_node)

## Each Read is for a Grouper Node and its' children
func _read_node(reader: ByteReader) -> void:
	var parent_path = reader.read_path_to()
	var num_nodes = reader.read_int()
	var grouper_node_id = reader.read_big_int()
	
	var grouper_node : NetworkedGrouperNode3D = get_node(parent_path)
#	var to_delete_nodes : Array[Node] = grouper_node.nodes
	
	for _i in range(num_nodes):
		var node_name = reader.read_str()
		var scene_path = reader.read_str()
		var global_pos = reader.read_vector3()
		var global_rot = reader.read_vector3()
		var num_net_nodes = reader.read_int()
		
		var node : Node = grouper_node.get_node_or_null(node_name)
		if node == null:
			node = NetworkingUtils.spawn_node_by_scene_path(scene_path, grouper_node)
#		elif to_delete_nodes.size() > 0:
#			var index = to_delete_nodes.find(node)
#			to_delete_nodes.remove_at(index)
		
		node.set_name.call_deferred(node_name)
		node.global_position = global_pos
		node.global_rotation = global_rot
		for i in num_net_nodes:
			var net_node_networked_id = reader.read_big_int()
			var net_node_global_position = reader.read_vector3()
			var net_node_global_rotation = reader.read_vector3()
#			var net_node_scene_id = reader.read_int()
			var net_node_scene_file_path = reader.read_str()
			var net_node_relative_path : String = reader.read_relative_path_to()
			
			var net_scene = node.get_node_or_null(net_node_relative_path)

			# Dynamic Spawn, likely a Holdable
			if net_scene == null:
				
#				net_scene = NetworkedScenes.get_scene_by_id(net_node_scene_id).instantiate()
				net_scene = load(net_node_scene_file_path).instantiate()
				var net_node : NetworkedNode3D = net_scene.get_node_or_null(NetworkingUtils.NETWORKED_NODE_3D)
				if net_node != null:
					net_node.networked_id = net_node_networked_id
					net_node.original_name = net_scene.name
					net_node.p_node = net_scene
				var split_path = net_node_relative_path.rsplit("/", true, 1)
				print("Setting Scene %s name to %s" % [net_scene.name, split_path[1]])
				net_scene.name = split_path[1]
				
				var net_scene_new_parent_path = split_path[0]
				var net_scene_new_parent = node.get_node_or_null(net_scene_new_parent_path)
				if net_scene_new_parent == null:
					printerr(net_scene_new_parent_path)
					node.print_tree_pretty()
				else:
					net_scene_new_parent.add_child(net_scene)
				
				net_scene.global_position = net_node_global_position
				net_scene.global_rotation = net_node_global_rotation
	
	grouper_node.ID = grouper_node_id
	
#	for to_delete in to_delete_nodes:
#		to_delete.queue_free()
