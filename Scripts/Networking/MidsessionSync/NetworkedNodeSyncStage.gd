extends SyncStage
class_name NetworkedNodeSyncStage

func _ready():
	name = "NetworkedNodeSyncStage"

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

func _sync_process(nodes: Array[Node]) -> void:
	for net_node in nodes as Array[NetworkedNode3D]:
		print_verbose("[Syncing Node %s | %s] to [Peer: %s]" % [net_node.priority_sync_order, net_node.p_node.name, peer_id])
		
		var writer = ByteWriter.new()
		writer.write_int(net_node.networked_id)
		writer.write_int(net_node.SCENE_ID)
		writer.append_array(net_node.get_sync_state().data)
		
		send_client_sync_data(writer.data)

func _receive_sync_data(data: PackedByteArray) -> int:
	var reader = ByteReader.new(data)
	var networked_id = reader.read_int()
	var net_scene_id = reader.read_int()
	var net_nodes = get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED))
	print_verbose("[Peer %s] received request to [sync Node %s]" % [multiplayer.get_unique_id(), networked_id])
	var synced = false

	# Sync existing Networked Nodes the Player starts with
	for net_node in net_nodes:
		if net_node.networked_id == networked_id:
			print_verbose("Found existing node ", net_node.p_node.name, " its parent is ", net_node.p_node.get_parent().name)
			net_node.set_sync_state(reader)
			synced = true
			break
		
	# TODO: this is finally a problem! YAYYY
	# If we didn't find one of the pre-existing nodes we start with, delete it!
	
	# Didn't find the Networked Node, need to spawn one
	if not synced:
		assert(NetworkedScenes.get_scene_by_id(net_scene_id) != null, "%s does not have a NetworkedIds.Scene PATH to instantiate from in SceneIds.gd")
		
		print_verbose("[Peer %s] didn't find %s in the objects on startup. The Player must have generated this at run time. [Spawning a %s with id %s]" \
			% [multiplayer.get_unique_id(), networked_id, NetworkedScenes.get_scene_by_id(net_scene_id).get_state().get_node_name(0), networked_id])
		
		# Spawn Networked Node
		# Add the node into the tree so that it can call get_node from within
		var net_scene = NetworkingUtils.spawn_node(NetworkedScenes.get_scene_by_id(net_scene_id), self)
		var net_node = net_scene.get_node("NetworkedNode3D")
		net_node.networked_id = networked_id
		net_node.set_sync_state(reader)
		net_node.changed = true
	
	return 1
