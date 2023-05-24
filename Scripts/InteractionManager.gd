extends Node

## Autoloaded

# Tell the Server we want to Interact, called from clients
func attempt_interaction(player : Player, interactable : Interactable, i_type : int):
	var p_id = player.name.to_int()
	var path_to_interactable = StringName(interactable.get_path()).to_utf32_buffer()
	if is_multiplayer_authority():
		resolve_interaction(p_id, path_to_interactable, i_type)
	else:
		resolve_interaction.rpc_id(1, p_id, path_to_interactable, i_type)

# Server figures out how to handle that Interaction and passes it along
@rpc("any_peer")
func resolve_interaction(p_id : int, path_to_interactable : PackedByteArray, i_type : int):
	if not is_multiplayer_authority():
		return
	
	var decoded_path = path_to_interactable.get_string_from_utf32()
	var player : Player = GameState.get_player_by_id(p_id)
	
	if player != null:
		var node = get_node_or_null(decoded_path)
		if node != null and node is Interactable:
			if i_type == 0:
				(node as Interactable).interact(player)
				notify_peers_of_interaction.rpc(p_id, path_to_interactable, i_type)
			elif i_type == 1:
				(node as Interactable).secondary_interact(player)
				notify_peers_of_interaction.rpc(p_id, path_to_interactable, i_type)

@rpc("authority", "call_remote")
func notify_peers_of_interaction(p_id : int, path_to_interactable : PackedByteArray, i_type : int):
	var decoded_path = path_to_interactable.get_string_from_utf32()
	var player : Player = GameState.get_player_by_id(p_id)
	
	if player != null:
		var node = get_node_or_null(decoded_path)
		if node != null and node is Interactable:
			if i_type == 0:
				(node as Interactable).interact(player)
			elif i_type == 1:
				(node as Interactable).secondary_interact(player)
				