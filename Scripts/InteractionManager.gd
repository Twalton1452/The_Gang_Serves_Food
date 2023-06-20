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
func attempt_edit_mode_interaction(player : Player, node : StaticBody3D, i_type : InteractionType):
	var p_id = player.name.to_int()
	var path_to_interactable = StringName(node.get_path()).to_utf32_buffer()
	if is_multiplayer_authority():
		resolve_edit_mode_interaction(p_id, path_to_interactable, i_type)
	else:
		resolve_edit_mode_interaction.rpc_id(GameState.SERVER_ID, p_id, path_to_interactable, i_type)

func attempt_edit_mode_secondary_interaction(player : Player):
	var p_id = player.name.to_int()
	var path_to_interactable = StringName(player.remote_transform.remote_path).to_utf32_buffer()
	if is_multiplayer_authority():
		resolve_edit_mode_interaction(p_id, path_to_interactable, InteractionType.SECONDARY)
	else:
		resolve_edit_mode_interaction.rpc_id(GameState.SERVER_ID, p_id, path_to_interactable, InteractionType.SECONDARY)

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
		player.edit_mode_ray_cast.lock_to = true
		player.remote_transform.global_position = node.owner.global_position
		player.remote_transform.remote_path = node.owner.get_path()
	if i_type == InteractionType.SECONDARY:
		node.rotation.y += PI / 2
	
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
		player.edit_mode_ray_cast.lock_to = true
		player.remote_transform.global_position = node.owner.global_position
		player.remote_transform.remote_path = node.owner.get_path()
	if i_type == InteractionType.SECONDARY:
		node.rotation.y += PI / 2

func attempt_edit_mode_placement(player : Player) -> void:
	var p_id = player.name.to_int()
	if is_multiplayer_authority():
		resolve_edit_mode_placement(p_id)
	else:
		resolve_edit_mode_placement.rpc_id(GameState.SERVER_ID, p_id)

# Server figures out how to handle that Interaction and passes it along
@rpc("any_peer")
func resolve_edit_mode_placement(p_id : int):
	if not is_multiplayer_authority():
		return
	
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null and player.remote_transform.remote_path != null:
		return
	
	var path_to_node = player.remote_transform.remote_path
	var node = get_node_or_null(path_to_node)
	if node == null:
		return
	
	player.edit_mode_ray_cast.lock_to = false
	player.remote_transform.remote_path = NodePath()
	player.remote_transform.position = Vector3.ZERO
	var writer = ByteWriter.new()
	writer.write_vector3(node.global_position)
	notify_peers_of_edit_mode_placement.rpc(p_id, writer.data)

@rpc("authority", "call_remote")
func notify_peers_of_edit_mode_placement(p_id : int, node_global_pos: PackedByteArray):
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var path_to_node = player.remote_transform.remote_path
	var node = get_node_or_null(path_to_node)
	if node == null:
		return
	
	player.edit_mode_ray_cast.lock_to = false
	player.remote_transform.remote_path = NodePath()
	player.remote_transform.position = Vector3.ZERO
	var reader = ByteReader.new(node_global_pos)
	node.global_position = reader.read_vector3()
	
