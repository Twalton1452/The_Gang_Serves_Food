extends SyncStage
class_name NetworkedNodeSpawnStage

const NETWORKED_NODE_BATCH_SIZE = 50
var existing_net_nodes : Array[Node] = []
## This is used for tracking if existing nodes in the starter Scene were deleted or not
var updated_existing_net_nodes : Dictionary = {}

func _ready():
	batch_size = NETWORKED_NODE_BATCH_SIZE

func _client_begin() -> void:
	existing_net_nodes = get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED))

func _client_finished() -> void:
	for net_node in existing_net_nodes as Array[NetworkedNode3D]:
		if not updated_existing_net_nodes.get(net_node.networked_id, false):
			print_verbose("[Deleting Existing Node %s] during %s phase" % [net_node.p_node.name, name])
			net_node.p_node.queue_free()
	existing_net_nodes.clear()
	updated_existing_net_nodes.clear()

func _write_node(node: Node, writer: ByteWriter) -> void:
	var net_node : NetworkedNode3D = node
	
	writer.write_int(net_node.networked_id)
	writer.write_int(net_node.SCENE_ID)
	writer.write_path_to(net_node.p_node)

func _read_node(reader: ByteReader) -> void:
	var networked_id = reader.read_int()
	var net_scene_id = reader.read_int()
	var path_to_p_node = reader.read_path_to()
	
	var net_node : NetworkedNode3D = null
	# Check to make sure the node doesn't already exist
	for node in existing_net_nodes:
		if node.networked_id == networked_id:
			net_node = node
			updated_existing_net_nodes[networked_id] = true
			break
	
	var split_path : PackedStringArray = path_to_p_node.split("/")
	var new_name = split_path[-1]
	var path_to_parent = "/".join(split_path.slice(0, -1))
	var new_parent = get_node(path_to_parent)
	
	# Node doesn't come in the pre-existing level - Spawn it
	if net_node == null:
		# Scene_id: NETWORKED nodes do not have spawnable scenes
		# They are attached to other scenes
		# We wrote the data anyway because its easier than developing some kind of "skip()" method
		# TODO: Revisit this
		if net_scene_id == NetworkedIds.Scene.NETWORKED:
			return
		print_verbose("[Peer %s] received request to [spawn Node %s]" % [multiplayer.get_unique_id(), networked_id])
		assert(NetworkedScenes.get_scene_by_id(net_scene_id) != null, "%s does not have a NetworkedIds.Scene PATH to instantiate from in SceneIds.gd")
		
		var net_scene = NetworkedScenes.get_scene_by_id(net_scene_id).instantiate()
		net_node = net_scene.get_node("NetworkedNode3D")
		# Since we are not adding the Scene to the tree until later, but we want to setup its name/id
		# We need to manually assign the @onready var's
		net_node.p_node = net_scene
		net_node.original_name = net_scene.name
		net_node.networked_id = networked_id
#		print(name, ": Spawned %s, assigned %s networked_id to: %s" % [net_scene.name, net_node.name, net_node.networked_id])
		if not net_node.only_one_will_exist:
			net_scene.name = new_name
		
		if new_parent is Holder:
			new_parent.hold_item(net_node.p_node)
		else:
			new_parent.add_child(net_node.p_node, true)
		
		return
	
	# Node came with pre-existing level, figure out the best way to shuffle parents around
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
#	for net_node in net_nodes:
#		print(net_node.priority_sync_order, " ", net_node.p_node.name)
	return net_nodes
