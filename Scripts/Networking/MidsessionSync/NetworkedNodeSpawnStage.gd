extends SyncStage
class_name NetworkedNodeSpawnStage

const NETWORKED_NODE_BATCH_SIZE = 50
#var existing_net_nodes : Array[Node] = []
## This is used for tracking if existing nodes in the starter Scene were deleted or not
#var updated_existing_net_nodes : Dictionary = {}

func _ready():
	batch_size = NETWORKED_NODE_BATCH_SIZE
	child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(_node: Node) -> void:
#	print("Spawned Node %s and parented it to %s" % [node.name, name])
	pass

#func _client_begin() -> void:
#	existing_net_nodes = get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED))
#
#func _client_finished() -> void:
#	for net_node in existing_net_nodes as Array[NetworkedNode3D]:
#		if not updated_existing_net_nodes.get(net_node.networked_id, false):
#			print_verbose("[Deleting Existing Node %s] during %s phase" % [net_node.p_node.name, name])
#			net_node.p_node.queue_free()
#	existing_net_nodes.clear()
#	updated_existing_net_nodes.clear()

func _write_node(node: Node, writer: ByteWriter) -> void:
	var net_node : NetworkedNode3D = node
	
	writer.write_big_int(net_node.networked_id)
	writer.write_int(net_node.SCENE_ID)
	writer.write_str(net_node.p_node.name)

func _read_node(reader: ByteReader) -> void:
	var networked_id = reader.read_big_int()
	var net_scene_id = reader.read_int()
	var p_node_name = reader.read_str()
	
	var net_node : NetworkedNode3D = null
	
	var net_scene : Node = null
	# Scene_id: NETWORKED nodes are spawned indirectly
	# They are generally attached to other scenes or a NetworkedGrouperNode3D
	# They still have NetworkedNode3D's attached to them because they manage some State
	# Ex: Rotatable on the Door of a Cabinet
	if net_scene_id == NetworkedIds.Scene.NETWORKED:
		print("NETWORKED SCENE ID ", p_node_name)
		return
	print_verbose("[Peer %s] received request to [spawn Node %s]" % [multiplayer.get_unique_id(), networked_id])
	assert(NetworkedScenes.get_scene_by_id(net_scene_id) != null, "%s does not have a NetworkedIds.Scene PATH to instantiate from in SceneIds.gd")
	net_scene = NetworkedScenes.get_scene_by_id(net_scene_id).instantiate()
	net_node = net_scene.get_node("NetworkedNode3D")
	
	# Since we are not adding the Scene to the tree until later, but we want to setup its name/id
	# We need to manually assign the @onready var's
	net_node.p_node = net_scene
	net_node.original_name = net_scene.name
	net_node.networked_id = networked_id
	add_child(net_node.p_node, true)
	
	net_scene = net_node.p_node

	if not net_node.only_one_will_exist:
		net_scene.name = p_node_name

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
