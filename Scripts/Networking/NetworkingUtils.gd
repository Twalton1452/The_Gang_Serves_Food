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
