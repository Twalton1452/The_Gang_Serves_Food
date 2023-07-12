extends SyncStage
class_name NetworkedNodeSyncStage

const NETWORKED_NODE_BATCH_SIZE = 50

func _ready():
	batch_size = NETWORKED_NODE_BATCH_SIZE

func _write_node(node: Node, writer: ByteWriter) -> void:
	var net_node : NetworkedNode3D = node
	writer.write_big_int(net_node.networked_id)
	net_node.get_sync_state(writer)

func _read_node(reader: ByteReader) -> void:
	var networked_id = reader.read_big_int()
	var net_nodes = get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED))
	print_verbose("[Peer %s] received request to [sync Node %s]" % [multiplayer.get_unique_id(), networked_id])
	var found = null
	for net_node in net_nodes:
		if net_node.networked_id == networked_id:
#			print(name, " Found existing node ", net_node.p_node.name, " its parent is ", net_node.p_node.get_parent().name)
			net_node.set_sync_state(reader)
			found = net_node
			break
	if found == null:
		printerr("Never found %s to sync" % networked_id)
#	else:
#		print("Syncd %s " % found.p_node.name)
	
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
	return net_nodes.filter(func(net_node): return net_node.changed)
