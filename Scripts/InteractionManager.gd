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
	var path_to_interactable = StringName(player.edit_mode_ray_cast.get_held_editable_path()).to_utf32_buffer()
	if is_multiplayer_authority():
		resolve_edit_mode_interaction(p_id, path_to_interactable, InteractionType.SECONDARY)
	else:
		resolve_edit_mode_interaction.rpc_id(GameState.SERVER_ID, p_id, path_to_interactable, InteractionType.SECONDARY)

func lock_on_to_node(player: Player, node: Node) -> void:
	player.edit_mode_ray_cast.lock_on_to(node)

func rotate_node(node: Node) -> void:
	node.rotation.y += PI / 2

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
		lock_on_to_node(player, node)
	if i_type == InteractionType.SECONDARY:
		rotate_node(node)
	
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
		lock_on_to_node(player, node)
	if i_type == InteractionType.SECONDARY:
		rotate_node(node)


func attempt_edit_mode_placement(player : Player) -> void:
	var p_id = player.name.to_int()
	if is_multiplayer_authority():
		resolve_edit_mode_placement(p_id)
	else:
		resolve_edit_mode_placement.rpc_id(GameState.SERVER_ID, p_id)

func release_placing_node(player: Player) -> void:
	player.edit_mode_ray_cast.unlock_from_target()

# Server figures out how to handle that Interaction and passes it along
@rpc("any_peer")
func resolve_edit_mode_placement(p_id : int):
	if not is_multiplayer_authority():
		return
	
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var node = player.edit_mode_ray_cast.get_held_editable_node()
	if node == null:
		return
	
	release_placing_node(player)
	var writer = ByteWriter.new()
	writer.write_vector3(node.global_position)
	notify_peers_of_edit_mode_placement.rpc(p_id, writer.data)

@rpc("authority", "call_remote")
func notify_peers_of_edit_mode_placement(p_id : int, node_global_pos: PackedByteArray):
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var node = player.edit_mode_ray_cast.get_held_editable_node()
	if node == null:
		return
	
	release_placing_node(player)
	var reader = ByteReader.new(node_global_pos)
	node.global_position = reader.read_vector3()


func buy_attempt() -> void:
	if not is_multiplayer_authority():
		attempt_to_buy_held_item.rpc_id(GameState.SERVER_ID, multiplayer.get_unique_id())
	else:
		attempt_to_buy_held_item(GameState.SERVER_ID)

@rpc("any_peer")
func attempt_to_buy_held_item(p_id: int) -> void:
	var player = GameState.get_player_by_id(p_id)
	if not player.edit_mode_ray_cast.is_holding_editable:
		return
	
	var node = player.edit_mode_ray_cast.get_held_editable_node()
	if node.scene_file_path.is_empty():
		return
	
	GameState.subtract_money(1)
	var data = {
		"global_position": node.global_position,
		"global_rotation": node.global_rotation,
	}
	var spawned_node = NetworkingUtils.spawn_node_by_scene_path_for_everyone(node.scene_file_path, node.get_parent(), data)
	print_debug(p_id, " Bought ", spawned_node)

func sell_attempt() -> void:
	if not is_multiplayer_authority():
		attempt_to_sell_held_item.rpc_id(GameState.SERVER_ID, multiplayer.get_unique_id())
	else:
		attempt_to_sell_held_item(GameState.SERVER_ID)

@rpc("any_peer")
func attempt_to_sell_held_item(p_id: int) -> void:
	var player = GameState.get_player_by_id(p_id)
	if not player.edit_mode_ray_cast.is_holding_editable:
		return
	
	var node = player.edit_mode_ray_cast.get_held_editable_node()
	if node.scene_file_path.is_empty():
		return
	
	var node_name = node.name
	GameState.add_money(1)
	NetworkingUtils.send_item_for_deletion(node)
	release_placing_node(player)
	print_debug(p_id, " sold ", node_name)
	
	notify_peers_player_sold_item.rpc(p_id)

@rpc("authority", "call_remote")
func notify_peers_player_sold_item(p_id: int) -> void:
	var player = GameState.get_player_by_id(p_id)
	
	release_placing_node(player)
