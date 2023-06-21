extends Node

var ID = 0
const NETWORKED_NODE_3D = "NetworkedNode3D"

# Used to sync from server to client on connection
@rpc("authority", "reliable")
func sync_id(id: int) -> void:
	print("[Sync %s] %s ID has been set to %d. Was: %s" % [name, multiplayer.get_unique_id(), id, ID])
	ID = id

func generate_id() -> int:
	ID += 1
	# print("[ID] %s now has ID at %d" % [multiplayer.get_unique_id(), ID])
	return ID

# Keeping the og_name might be redundant data, but helpful during development
func generate_network_safe_name(og_name: String) -> String:
	return og_name + "_" + str(generate_id())

func get_networked_node_by_id(networked_id: int) -> NetworkedNode3D:
	var networked_nodes = get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED))
	for net_node in networked_nodes:
		if net_node.networked_id == networked_id:
			return net_node
	return null

func sort_array_by_net_id(arr: Array) -> void:
	arr.sort_custom(func(a: Node, b: Node):
		if a.get_node(NETWORKED_NODE_3D).networked_id < b.get_node(NETWORKED_NODE_3D).networked_id:
			return true
		return false
	)

func spawn_node(node_to_spawn: PackedScene, to_be_parent: Node) -> Node:
	var spawned_node = node_to_spawn.instantiate()
	to_be_parent.add_child(spawned_node, true)
	
	# Only the server cares about the NetworkedNode3D sync orders
	# If the player needs that too, then remove this
	if not is_multiplayer_authority():
		return spawned_node
	
	ensure_correct_sync_order_for(spawned_node)
	
	return spawned_node

func spawn_node_for_everyone(node_to_spawn: PackedScene, to_be_parent: Node) -> Node:
	if not is_multiplayer_authority():
		return null
	
	var spawned_node = spawn_node(node_to_spawn, to_be_parent)
	
	var net_node : NetworkedNode3D = spawned_node.get_node(NETWORKED_NODE_3D)
	var writer = ByteWriter.new()
	writer.write_int(net_node.SCENE_ID)
	writer.write_path_to(to_be_parent)
	#writer.data.append_array(net_node.get_sync_state().data)
	spawn_node_for_peers.rpc(writer.data)
	return spawned_node

func duplicate_node(node_to_duplicate: Node, to_be_parent: Node, deep_copy_state = false) -> Node:
	var duplicated_node = node_to_duplicate.duplicate()
	to_be_parent.add_child(duplicated_node, true)
	
	if deep_copy_state:
		var data = PackedByteArray()
		get_sync_data_for(node_to_duplicate, data)
		set_sync_data_for(duplicated_node, ByteReader.new(data))
	
	# Only the server cares about the NetworkedNode3D sync orders
	# If the player needs that too, then remove this
	if not is_multiplayer_authority():
		return duplicated_node
	
	ensure_correct_sync_order_for(duplicated_node)
	
	return duplicated_node

func duplicate_node_for_everyone(node_to_duplicate: Node, to_be_parent: Node, deep_copy_state = false) -> Node:
	if not is_multiplayer_authority():
		return null
	
	var duplicated_node = duplicate_node(node_to_duplicate, to_be_parent, deep_copy_state)

	var writer = ByteWriter.new()
	writer.write_path_to(node_to_duplicate)
	writer.write_path_to(to_be_parent)
	writer.write_bool(deep_copy_state)
	duplicate_node_for_peers.rpc(writer.data)
	
	return duplicated_node

## Makes sure children's state is sync'd after their parents
func ensure_correct_sync_order_for(node: Node) -> void:
	var net_node : NetworkedNode3D = node.get_node(NETWORKED_NODE_3D)
	
	@warning_ignore("int_as_enum_without_cast")
	net_node.priority_sync_order = crawl_up_tree_for_next_priority_sync_order(node)
#	net_node.changed = true
	
	set_priority_sync_order_for_children_of(node, net_node.priority_sync_order)

## Find the first parent of this node that has a priority_sync_order to set it after
func crawl_up_tree_for_next_priority_sync_order(node: Node) -> int:
	if node.get_parent() == null:
		return 0
	var parent_net_node = node.get_parent().get_node_or_null(NETWORKED_NODE_3D)
	if parent_net_node != null:
		return parent_net_node.priority_sync_order + 1
	return crawl_up_tree_for_next_priority_sync_order(node.get_parent())

## Recursively set the priority_sync_order of all the children to be 1 more than their parent
func set_priority_sync_order_for_children_of(node: Node, sync_order: int) -> void:
	for child in node.get_children():
		var child_net_node = child.get_node_or_null(NETWORKED_NODE_3D)
		if child_net_node != null:
			child_net_node.priority_sync_order = sync_order + 1
			set_priority_sync_order_for_children_of(child, child_net_node.priority_sync_order)
		else:
			set_priority_sync_order_for_children_of(child, sync_order)

## Get the sync_state of the node and all of its children
## use [set_sync_data_for] to set the data
func get_sync_data_for(node: Node, data : PackedByteArray) -> void:
	var net_node : NetworkedNode3D = node.get_node_or_null(NETWORKED_NODE_3D)
	if net_node != null:
		data.append_array(net_node.get_stateful_sync_state().data)
	get_sync_data_for_children_of(node, data)

## Recursively get the sync_state of all the children for a particular Node
func get_sync_data_for_children_of(node: Node, data : PackedByteArray) -> void:
	for child in node.get_children():
		var child_net_node : NetworkedNode3D = child.get_node_or_null(NETWORKED_NODE_3D)
		if child_net_node != null:
			data.append_array(child_net_node.get_stateful_sync_state().data)
		get_sync_data_for_children_of(child, data)

## Set the sync_state of the node and all of its children
## use [get_sync_data_for] to generate the data
func set_sync_data_for(node: Node, reader: ByteReader) -> void:
	var net_node : NetworkedNode3D = node.get_node_or_null(NETWORKED_NODE_3D)
	if net_node != null:
		net_node.set_stateful_sync_state(reader)
	
	set_sync_data_for_children_of(node, reader)

## Recursively set the sync_state of all the children for a particular Node
## use [get_sync_data_for_children_of] to generate the data
func set_sync_data_for_children_of(node: Node, reader: ByteReader) -> void:
	for child in node.get_children():
		var child_net_node : NetworkedNode3D = child.get_node_or_null(NETWORKED_NODE_3D)
		if child_net_node != null:
			child_net_node.set_stateful_sync_state(reader)
		set_sync_data_for_children_of(child, reader)

func notify_child_net_nodes_changed(node: Node) -> void:
	for child in node.get_children():
		var networked_node : NetworkedNode3D = child.get_node_or_null(NETWORKED_NODE_3D)
		if networked_node != null:
			networked_node.changed = true
		notify_child_net_nodes_changed(child)

## Spawn a Node that is managed by the client, no networking attached to it
func spawn_client_only_node(node_to_spawn: PackedScene, to_be_parent: Node) -> Node:
	var spawned_node = node_to_spawn.instantiate()
	
	var spawned_net_node : NetworkedNode3D = spawned_node.get_node_or_null(NETWORKED_NODE_3D)
	if spawned_net_node != null:
		spawned_node.remove_child(spawned_net_node)
		spawned_net_node.queue_free()
	
	to_be_parent.add_child(spawned_node, true)
	return spawned_node

func send_partial_state_update(node: Node) -> void:
	var net_node : NetworkedNode3D = node.get_node_or_null(NETWORKED_NODE_3D)
	if net_node != null:
		partial_state_update_for_peers.rpc(net_node.networked_id, net_node.get_stateful_sync_state().data)

func send_item_for_deletion(item: Node) -> void:
	if not is_multiplayer_authority():
		return
	
	var networked_node_3d = item.get_node_or_null(NETWORKED_NODE_3D)
	if networked_node_3d != null:
		delete_item_for_everyone_by_networked_id.rpc(networked_node_3d.networked_id)
	else:
		delete_item_for_everyone_by_path.rpc(StringName(item.get_path()).to_utf8_buffer())

@rpc("authority", "call_remote", "reliable")
func spawn_node_for_peers(data: PackedByteArray):
	# TODO: In the future all RPC calls could be filtered through a RPC Queue
	# The RPCs would sit in a wait list to be executed until syncing is complete
	# Then we wouldn't need to wait for this logic or pause the game either
	if not MidsessionJoinSyncer.is_synced:
		await MidsessionJoinSyncer.accept_rpcs
	
	var reader = ByteReader.new(data)
	var scene_id = reader.read_int()
	var to_be_parent = get_node(reader.read_path_to())
	spawn_node(NetworkedScenes.get_scene_by_id(scene_id), to_be_parent)
#	var net_node = spawned_node.get_node(NETWORKED_NODE_3D)
#	net_node.set_sync_state(reader)

@rpc("authority", "call_remote", "reliable")
func duplicate_node_for_peers(data: PackedByteArray):
	# TODO: In the future all RPC calls could be filtered through a RPC Queue
	# The RPCs would sit in a wait list to be executed until syncing is complete
	# Then we wouldn't need to wait for this logic or pause the game either
	if not MidsessionJoinSyncer.is_synced:
		print("Trying to duplicate but not synced yet, waiting...")
		await MidsessionJoinSyncer.accept_rpcs
		print("sync completed, proceeding with duplication")
	
	var reader = ByteReader.new(data)
	var node_to_duplicate = get_node(reader.read_path_to())
	var to_be_parent = get_node(reader.read_path_to())
	var deep_copy_state = reader.read_bool()
	duplicate_node(node_to_duplicate, to_be_parent, deep_copy_state)

@rpc("authority", "call_remote")
func partial_state_update_for_peers(networked_id: int, data: PackedByteArray):
	var networked_node_to_update = get_networked_node_by_id(networked_id)
	if networked_node_to_update == null:
		print_debug("Networked Node with ID: %s doesn't exist" % networked_id)
		return
	
	networked_node_to_update.set_stateful_sync_state(ByteReader.new(data))

@rpc("authority", "call_local")
func delete_item_for_everyone_by_networked_id(networked_id: int):
	var networked_node_to_delete = get_networked_node_by_id(networked_id)
	if networked_node_to_delete == null:
		print_debug("Networked Node with ID: %s doesn't exist" % networked_id)
		return
	
	networked_node_to_delete.p_node.queue_free()

@rpc("authority", "call_local")
func delete_item_for_everyone_by_path(path: PackedByteArray):
	var decoded_path = path.get_string_from_utf8()
	var node = get_node_or_null(decoded_path)
	
	if node != null:
		node.queue_free()
	else:
		print("Could not find %s" % decoded_path)

## RESOURCE SENDING
#func _unhandled_input(event):
#	if event is InputEventKey and event.is_action_pressed("ui_down"):
#		send_a_resource_to_everyone()

#func save_on_server():
#  ResourceSaver.save(resource_used_as_savefile, path)
#  var file=File.new()
#  file.open(path, File.READ)
#  load_on_client.rpc(file.get_buffer(file.get_len()))
#  file.close()
#
#@rpc("authority", "call_remote")
#func load_on_client(buffer):
# var file=File.new()
# file.open(path_to_temp, File.WRITE)
# file.store_buffer(buffer)
# file.close()
# resource_used_as_savefile=load(path_to_temp)
