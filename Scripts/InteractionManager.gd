extends Node

## Autoloaded

enum InteractionType {
	PRIMARY = 0,
	SECONDARY = 1,
}

# Tell the Server we want to Interact, called from clients
func attempt_interaction(player : Player, interactable : Interactable, i_type : InteractionType):
	var p_id = player.name.to_int()
	var path_to_interactable = StringName(interactable.get_path()).to_utf32_buffer()
	if is_multiplayer_authority():
		resolve_interaction(p_id, path_to_interactable, i_type)
	else:
		resolve_interaction.rpc_id(GameState.SERVER_ID, p_id, path_to_interactable, i_type)

# Server figures out how to handle that Interaction and passes it along
@rpc("any_peer")
func resolve_interaction(p_id : int, path_to_interactable : PackedByteArray, i_type : int):
	if not is_multiplayer_authority():
		return
	
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var decoded_path = path_to_interactable.get_string_from_utf32()
	var node = get_node_or_null(decoded_path)
	if node == null or not node is Interactable:
		return
	
	if i_type == InteractionType.PRIMARY:
		(node as Interactable).interact(player)
		notify_peers_of_interaction.rpc(p_id, path_to_interactable, i_type)
	elif i_type == InteractionType.SECONDARY:
		(node as Interactable).secondary_interact(player)
		notify_peers_of_interaction.rpc(p_id, path_to_interactable, i_type)

@rpc("authority", "call_remote")
func notify_peers_of_interaction(p_id : int, path_to_interactable : PackedByteArray, i_type : int):
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var decoded_path = path_to_interactable.get_string_from_utf32()
	var node = get_node_or_null(decoded_path)
	if node == null or not node is Interactable:
		return
	
	if i_type == InteractionType.PRIMARY:
		(node as Interactable).interact(player)
	elif i_type == InteractionType.SECONDARY:
		(node as Interactable).secondary_interact(player)


# Tell the Server we want to Interact, called from clients
func attempt_edit_mode_interaction(player : Player, node : Node3D, i_type : InteractionType):
	var p_id = player.name.to_int()
	var path_to_interactable = StringName(node.get_path()).to_utf32_buffer()
	if is_multiplayer_authority():
		resolve_edit_mode_interaction(p_id, path_to_interactable, i_type)
	else:
		resolve_edit_mode_interaction.rpc_id(GameState.SERVER_ID, p_id, path_to_interactable, i_type)

# Server figures out how to handle that Interaction and passes it along
@rpc("any_peer")
func resolve_edit_mode_interaction(p_id : int, path_to_interactable : PackedByteArray, i_type : int):
	if not is_multiplayer_authority():
		return
	
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var decoded_path = path_to_interactable.get_string_from_utf32()
	var node = get_node_or_null(decoded_path)
	if node == null:
		return
	
	if i_type == InteractionType.PRIMARY:
		if player.holder.is_holding_item():
			return
	
		player.holder.hold_item(node)
		notify_peers_of_edit_mode_interaction.rpc(p_id, path_to_interactable, i_type)
	elif i_type == InteractionType.SECONDARY:
		notify_peers_of_edit_mode_interaction.rpc(p_id, path_to_interactable, i_type)

@rpc("authority", "call_remote")
func notify_peers_of_edit_mode_interaction(p_id : int, path_to_interactable : PackedByteArray, i_type : int):
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var decoded_path = path_to_interactable.get_string_from_utf32()
	var node = get_node_or_null(decoded_path)
	if node == null:
		return
	
	if i_type == InteractionType.PRIMARY:
		player.holder.hold_item(node)
	elif i_type == InteractionType.SECONDARY:
		player.holder.hold_item(node)
	
