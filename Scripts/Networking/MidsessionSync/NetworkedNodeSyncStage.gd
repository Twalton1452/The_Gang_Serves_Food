extends SyncStage
class_name NetworkedNodeSyncStage

const NETWORKED_NODE_BATCH_SIZE = 50

func _ready():
	name = "NetworkedNodeSyncStage"
	batch_size = NETWORKED_NODE_BATCH_SIZE

func _write_node(node: Node, writer: ByteWriter) -> void:
	var net_node : NetworkedNode3D = node
	writer.write_big_int(net_node.networked_id)
	writer.append_array(net_node.get_sync_state().data)

func _read_node(reader: ByteReader) -> void:
	var networked_id = reader.read_big_int()
	var net_nodes = get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED))
	print_verbose("[Peer %s] received request to [sync Node %s]" % [multiplayer.get_unique_id(), networked_id])

	for net_node in net_nodes:
		if net_node.networked_id == networked_id:
#			print(name, " Found existing node ", net_node.p_node.name, " its parent is ", net_node.p_node.get_parent().name)
			net_node.set_sync_state(reader)
			break
	
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
	
	return net_nodes.filter(func(net_node): return net_node.changed)
