extends SyncStage
class_name NetworkedNodeParentStage

const NETWORKED_NODE_BATCH_SIZE = 50

func _ready():
	batch_size = NETWORKED_NODE_BATCH_SIZE

func _write_node(node: Node, writer: ByteWriter) -> void:
	var net_node : NetworkedNode3D = node
	
	writer.write_big_int(net_node.networked_id)
	writer.write_path_to(net_node.p_node.get_parent())

func _read_node(reader: ByteReader) -> void:
	var networked_id = reader.read_big_int()
	var path_to_p_node = reader.read_path_to()
	
	var net_node : NetworkedNode3D = NetworkingUtils.get_networked_node_by_id(networked_id)
	
	if net_node == null:
		printerr("Couldn't find ID: %s Parent Path: %s" % [networked_id, path_to_p_node])
		return
	
	var new_parent_node = get_node_or_null(path_to_p_node)
	if new_parent_node == null:
		printerr("Could find parent node, Path: %s" % path_to_p_node)
		return
	
	print_verbose("[Peer %s] received request to [parent Node %s] %s" % [multiplayer.get_unique_id(), networked_id, net_node.p_node])
	
	if net_node.p_node.get_parent() == new_parent_node:
#		print("%s had the same parent, not moving it" % net_node.p_node.get_parent())
		return
	
	if net_node.p_node.get_parent() is Holder and new_parent_node is Holder:
		net_node.p_node.get_parent().release_this_item_to(net_node.p_node, new_parent_node)
#		print("Moved %s to %s" % [net_node.p_node, new_parent_node])
	elif new_parent_node is Holder:
		new_parent_node.hold_item(net_node.p_node)
#		print("%s now holding %s" % [new_parent_node, net_node.p_node])
	else:
		net_node.p_node.reparent(new_parent_node)
#		print("Reparented %s to %s" % [net_node.p_node, new_parent_node])
	
func _nodes_to_sync() -> Array[Node]:
	var net_nodes = get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED))
	
	# Lower number for priority is sync'd first
	net_nodes.sort_custom(func(a: NetworkedNode3D, b: NetworkedNode3D):
		if a.priority_sync_order < b.priority_sync_order:
			if a.networked_id > b.networked_id:
				return 2
			return 1
		return 0
	)
#	for net_node in net_nodes:
#		print(net_node.priority_sync_order, " ", net_node.p_node.name)
	return net_nodes
