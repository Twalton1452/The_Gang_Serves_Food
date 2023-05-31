extends Node

var ID = 0

# Used to sync from server to client on connection
@rpc("any_peer", "reliable")
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

func sort_array_by_net_id(arr: Array) -> void:
	arr.sort_custom(func(a: Node, b: Node):
		if a.get_node("NetworkedNode3D").networked_id < b.get_node("NetworkedNode3D").networked_id:
			return true
		return false
	)

func send_item_for_deletion(item: Node) -> void:
	if not is_multiplayer_authority():
		return
	
	var networked_node_3d = item.get_node_or_null("NetworkedNode3D")
	if networked_node_3d != null:
		delete_item_for_everyone_by_networked_id.rpc(networked_node_3d.networked_id)
	else:
		delete_item_for_everyone_by_path.rpc(StringName(item.get_path()).to_utf8_buffer())

@rpc("authority", "call_local")
func delete_item_for_everyone_by_networked_id(networked_id: int):
	var networked_nodes = get_tree().get_nodes_in_group(str(SceneIds.SCENES.NETWORKED))
	var networked_node_to_delete : NetworkedNode3D = null
	for net_node in networked_nodes:
		if net_node.networked_id == networked_id:
			networked_node_to_delete = net_node
			break
	
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
