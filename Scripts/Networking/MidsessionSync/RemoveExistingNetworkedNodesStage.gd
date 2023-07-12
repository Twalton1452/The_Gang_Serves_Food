extends SyncStage
class_name RemoveExistingNetworkedNodesStage

var to_clean_up_callables : Array[Callable] = []

func register_nodes_to_cleanup(node_fetcher: Callable) -> void:
	to_clean_up_callables.push_back(node_fetcher)

func get_deletable_nodes() -> Array[Node]:
	var deletable_nodes : Array[Node] = []
	for callable in to_clean_up_callables:
		for node in callable.call():
			if node is NetworkedGrouperNode3D:
				deletable_nodes.append_array(node.nodes)
			elif node is NetworkedNode3D and not node.only_one_will_exist:
				deletable_nodes.push_back(node.p_node)
	return deletable_nodes
	
func _ensure_sync_nodes_are_ready() -> void:
	get_tree().paused = false
	# Wait a frame so that the nodes can be deleted
	await get_tree().physics_frame
#	print("[%s] Ensuring nodes are ready" % name)

	var nodes : Array[Node] = get_deletable_nodes()
	if nodes.size() > 0:
		print("[%s] still has nodes being deleted, waiting 2 frames" % name)
		print(nodes)
		await get_tree().physics_frame
		await get_tree().physics_frame
	
	nodes = get_deletable_nodes()
	if nodes.size() > 0:
		printerr("[%s] still has nodes being deleted, something is going wrong! See below array" % name)
		print(nodes)
	get_tree().paused = true

func _write_node(_node: Node, writer: ByteWriter) -> void:
	writer.write_int(0)

func _read_node(_reader: ByteReader) -> void:
	var nodes : Array[Node] = get_deletable_nodes()
	
	print("[%s] about to delete at least %s nodes" % [name, nodes.size()])
	
	var i = 0
	while i < nodes.size():
		if nodes[i] == null or nodes[i].is_queued_for_deletion():
			i += 1
			continue
		
		nodes[i].queue_free()
		i += 1
	
	print("[%s] deleted at least %s nodes" % [name, nodes.size()])

func _nodes_to_sync() -> Array[Node]:
	return [null]
