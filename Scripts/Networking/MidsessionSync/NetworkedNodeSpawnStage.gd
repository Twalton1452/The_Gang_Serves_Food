extends SyncStage
class_name NetworkedNodeSpawnStage

const NETWORKED_NODE_BATCH_SIZE = 50

func _ready():
	name = "NetworkedNodeSpawnStage"
	batch_size = NETWORKED_NODE_BATCH_SIZE

func _write_node(node: Node, writer: ByteWriter) -> void:
	var net_node : NetworkedNode3D = node
	
	writer.write_int(net_node.networked_id)
	writer.write_int(net_node.SCENE_ID)
	writer.write_vector3(net_node.p_node.global_position)
	writer.write_path_to(net_node.p_node)

func _read_node(reader: ByteReader) -> void:
	var networked_id = reader.read_int()
	var net_scene_id = reader.read_int()
	var global_pos = reader.read_vector3()
	var path_to_p_node = reader.read_path_to()
	
	# Scene_id: NETWORKED nodes do not have spawnable scenes
	# They are attached to other scenes
	# We wrote the data anyway because its easier than developing some kind of "skip()" method
	if net_scene_id == NetworkedIds.Scene.NETWORKED:
		return
	
	var net_node : NetworkedNode3D = null
	# Check to make sure the node doesn't already exist
	for node in get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED)):
		if node.networked_id == networked_id:
			net_node = node
			break
	
	print_verbose("[Peer %s] received request to [spawn Node %s]" % [multiplayer.get_unique_id(), networked_id])
	
	# Node doesn't come in the pre-existing level - Spawn it
	if net_node == null:
		assert(NetworkedScenes.get_scene_by_id(net_scene_id) != null, "%s does not have a NetworkedIds.Scene PATH to instantiate from in SceneIds.gd")
		# Add the node into the tree so that it can call get_node from within
		var net_scene = NetworkingUtils.spawn_node(NetworkedScenes.get_scene_by_id(net_scene_id), self)
		net_node = net_scene.get_node("NetworkedNode3D")
		net_node.networked_id = networked_id
	
	if net_node.sync_position:
		net_node.p_node.global_position = global_pos
	
	var split_path : PackedStringArray = path_to_p_node.split("/")
	var new_name = split_path[-1]
	var path_to_parent = "/".join(split_path.slice(0, -1))
	var new_parent = get_node(path_to_parent)
	
	if not net_node.only_one_will_exist:
		net_node.p_node.name = new_name
	
	if net_node.p_node.get_parent() != new_parent:
		if net_node.p_node.get_parent() is Holder and new_parent is Holder:
			net_node.p_node.get_parent().release_this_item_to(net_node.p_node, new_parent)
		elif new_parent is Holder:
			new_parent.hold_item(net_node.p_node)
		else:
			net_node.p_node.reparent(new_parent)
	
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
