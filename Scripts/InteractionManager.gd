extends Node

## Autoloaded
## Class for accepting Player Actions and resolving them
## Clients will send an RPC to the Server for that Action to be resolved
## Server will handle the Action and then notify the peers of the result

signal edit_mode_node_placed(node: Node)
signal edit_mode_node_bought(node: Node)

const ROTATION_AMOUNT = PI / 2

func not_implemented_action(p_id: int) -> void:
	printerr(p_id, " tried to call a not implemented action")

func get_open_for_business_action(player_action: Player.Action) -> Callable:
	match player_action:
		Player.Action.INTERACT: return resolve_interaction
		Player.Action.SECONDARY_INTERACT: return resolve_secondary_interaction
		Player.Action.BUY: return resolve_buying_held_item
		Player.Action.SELL: return resolve_selling_held_item
		_: return not_implemented_action

func get_editing_restaurant_action(player_action: Player.Action) -> Callable:
	match player_action:
		Player.Action.INTERACT: return resolve_edit_mode_interaction
		Player.Action.SECONDARY_INTERACT: return resolve_edit_mode_secondary_interaction
		Player.Action.BUY: return resolve_buying_held_item
		Player.Action.SELL: return resolve_selling_held_item
		_: return not_implemented_action
	
func resolve_player_action(player: Player, player_action: Player.Action) -> void:
	var p_id = player.name.to_int()
	var action: Callable = not_implemented_action
	
	# TODO: Player can swap between Layout editing and Interactable Editing
	if GameState.state == GameState.Phase.OPEN_FOR_BUSINESS:
		action = get_open_for_business_action(player_action)
	elif GameState.state == GameState.Phase.EDITING_RESTAURANT:
		action = get_editing_restaurant_action(player_action)
	else:
		printerr("Phase actions not implemented for GameState: ", GameState.state)
		return
	
	if is_multiplayer_authority():
		action.call(p_id)
	else:
		action.rpc_id(GameState.SERVER_ID, p_id)

func lock_on_to_node(player: Player, node: Node) -> void:
	player.edit_mode_ray_cast.lock_on_to(node)

func release_placing_node(player: Player) -> void:
	edit_mode_node_placed.emit(player.edit_mode_ray_cast.get_held_editable_node())
	player.edit_mode_ray_cast.unlock_from_target()

@rpc("any_peer")
func resolve_interaction(p_id: int):
	if not is_multiplayer_authority():
		return
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var interactable : Interactable = player.interact_ray_cast.get_collider()
	if interactable == null or not interactable is Interactable:
		return
	
	var writer = ByteWriter.new()
	writer.write_big_int(p_id)
	writer.write_path_to(interactable)
	
	interactable.interact(player)
	
	notify_peers_of_interaction.rpc(writer.data)

@rpc("authority", "call_remote")
func notify_peers_of_interaction(data : PackedByteArray):
	var reader = ByteReader.new(data)
	var p_id = reader.read_big_int()
	var path_to_interactable = reader.read_path_to()
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var interactable : Interactable = get_node_or_null(path_to_interactable)
	if interactable == null or not interactable is Interactable:
		return
	
	interactable.interact(player)

@rpc("any_peer")
func resolve_secondary_interaction(p_id: int):
	if not is_multiplayer_authority():
		return
	
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var interactable : Interactable = player.interact_ray_cast.get_collider()
	if interactable == null or not interactable is Interactable:
		return
	
	var writer = ByteWriter.new()
	writer.write_big_int(p_id)
	writer.write_path_to(interactable)
	
	interactable.secondary_interact(player)
	notify_peers_of_secondary_interaction.rpc(writer.data)

@rpc("authority", "call_remote")
func notify_peers_of_secondary_interaction(data: PackedByteArray):
	var reader = ByteReader.new(data)
	var p_id = reader.read_big_int()
	var path_to_interactable = reader.read_path_to()
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var interactable = get_node_or_null(path_to_interactable)
	if interactable == null or not interactable is Interactable:
		return
	
	interactable.secondary_interact(player)

@rpc("any_peer")
func resolve_edit_mode_interaction(p_id: int):
	if not is_multiplayer_authority():
		return
	
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var writer = ByteWriter.new()
	writer.write_big_int(p_id)
	# Placement
	if player.edit_mode_ray_cast.is_holding_editable:
		var held_node = player.edit_mode_ray_cast.get_held_editable_node()
		release_placing_node(player)
		
		writer.write_path_to(held_node)
		writer.write_vector3(held_node.global_position)
		notify_peers_of_edit_mode_placement.rpc(writer.data)
	# Picking up
	else:
		var node = player.edit_mode_ray_cast.get_collider()
		if node == null:
			return
		lock_on_to_node(player, node)
		
		writer.write_path_to(node)
		notify_peers_of_edit_mode_interaction.rpc(writer.data)

@rpc("authority", "call_remote")
func notify_peers_of_edit_mode_placement(data: PackedByteArray):
	var reader = ByteReader.new(data)
	var p_id = reader.read_big_int()
	var path_to_node = reader.read_path_to()
	var global_pos = reader.read_vector3()
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var node = get_node_or_null(path_to_node)
	if node == null:
		return
	
	release_placing_node(player)
	node.global_position = global_pos

@rpc("authority", "call_remote")
func notify_peers_of_edit_mode_interaction(data: PackedByteArray):
	var reader = ByteReader.new(data)
	var p_id = reader.read_big_int()
	var path_to_node = reader.read_path_to()
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var node = get_node_or_null(path_to_node)
	if node == null:
		return
	
	lock_on_to_node(player, node)

@rpc("any_peer")
func resolve_edit_mode_secondary_interaction(p_id : int):
	if not is_multiplayer_authority():
		return
	
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var to_rotate_node : Node3D = null
	
	if player.edit_mode_ray_cast.is_holding_editable:
		to_rotate_node = player.edit_mode_ray_cast.get_held_editable_node()
	else:
		if player.edit_mode_ray_cast.is_colliding():
			to_rotate_node = player.edit_mode_ray_cast.get_collider().owner
	
	if to_rotate_node == null:
		return
	to_rotate_node.rotation.y += ROTATION_AMOUNT
	
	var writer = ByteWriter.new()
	writer.write_big_int(p_id)
	writer.write_vector3(to_rotate_node.global_rotation)
	writer.write_path_to(to_rotate_node)
	notify_peers_of_edit_mode_rotation.rpc(writer.data)

@rpc("authority", "call_remote")
func notify_peers_of_edit_mode_rotation(data: PackedByteArray):
	var reader = ByteReader.new(data)
	var p_id = reader.read_big_int()
	var global_rot = reader.read_vector3()
	var path_to_rotate_node = reader.read_path_to()
	var player : Player = GameState.get_player_by_id(p_id)
	if player == null:
		return
	
	var node = get_node_or_null(path_to_rotate_node)
	if node == null:
		return
	
	node.global_rotation = global_rot

@rpc("any_peer")
func resolve_buying_held_item(p_id: int) -> void:
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
	var to_be_parent = Utils.crawl_up_for_grouper_node(node)
	if to_be_parent == null:
		to_be_parent = node.get_parent()
	var spawned_node = NetworkingUtils.spawn_node_by_scene_path_for_everyone(node.scene_file_path, to_be_parent, data)
	edit_mode_node_bought.emit(spawned_node)
	print(p_id, " Bought ", spawned_node)

@rpc("any_peer")
func resolve_selling_held_item(p_id: int) -> void:
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
	print(p_id, " sold ", node_name)
	
	notify_peers_player_sold_item.rpc(p_id)

@rpc("authority", "call_remote")
func notify_peers_player_sold_item(p_id: int) -> void:
	var player = GameState.get_player_by_id(p_id)
	
	release_placing_node(player)
