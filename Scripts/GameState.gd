extends Node

## Autoloaded

signal state_changed
signal money_changed(value: float)

var SERVER_ID = 1
## Used for debugging, shows ID of GameState to make looking at the Remote SceneTree easier
var THIS_ID = -1
var player_color : Color
var state : Phase = Phase.EDITING_RESTAURANT : set = set_state
var modifiers : GameModifiers = preload("res://Resources/GameModifiers/StarterModifiers.tres")
var money : float = 0.0 # Good use case for "Watched" Property in Godot 4.1
var multiholder_multiplier : float = 1.5
var combined_food_multiplier : float = 1.5 ## multiply per food in the stack

enum Phase {
	LOBBY,
	EDITING_RESTAURANT,
	OPEN_FOR_BUSINESS,
}

const STATE_NOTIFICATIONS = {
	Phase.EDITING_RESTAURANT: "Editing Restaurant",
	Phase.OPEN_FOR_BUSINESS: "Open for Business",
}

class Validation:
	var phase: Phase
	var error_message: String
	var validator: Callable
	
	func _init(phase_to_check: Phase, callable: Callable, err_msg: String) -> void:
		phase = phase_to_check
		validator = callable
		error_message = err_msg

## Call register_validator(Phase, Dictionary) for GameState to make sure
## that condition is met before it can switch to that Phase
var STATE_VALIDATIONS = {
	Phase.EDITING_RESTAURANT: [],
	Phase.OPEN_FOR_BUSINESS: [],
}


## Player str(id) is the key and the Player Node is the value
var players : Dictionary = {}
var level : GameLevel : set = set_level
var hud : HUD = null

func set_sync_state(reader: ByteReader):
	set_money(reader.read_float())
	var current_validations = STATE_VALIDATIONS
	STATE_VALIDATIONS = {}
	state = reader.read_int() as Phase
	STATE_VALIDATIONS = current_validations
	modifiers.set_sync_state(reader)

func get_sync_state() -> ByteWriter:
	var writer : ByteWriter = ByteWriter.new()
	writer.write_float(money)
	writer.write_int(state)
	writer.append_array(modifiers.get_sync_state().data)
	return writer

## target_phase_to_prevent: Phase - When switching to this phase, ensure the validator is true
## validator: Dictionary{ "validator": Callable -> bool, "err_message": String }
func register_validator(phase: Phase, callable: Callable, error_message: String) -> void:
	var new_validation = Validation.new(phase, callable, error_message)
	STATE_VALIDATIONS[new_validation.phase].push_back(new_validation)

func unregister_validator(phase: Phase, callable: Callable) -> void:
	var index = 0
	for validator in STATE_VALIDATIONS[phase]:
		if validator.validator == callable:
			break
		index += 1
	STATE_VALIDATIONS[phase].remove_at(index)

func set_state(value: Phase):
	for validation in STATE_VALIDATIONS.get(value, []) as Array[Validation]:
		if !validation.validator.call():
			hud.display_notification(validation.error_message, 2.0)
			return
			
	state = value
	state_changed.emit()
	
	var notification_text = STATE_NOTIFICATIONS.get(state)
	if notification_text != null:
		hud.display_notification(notification_text, 1.0)
		
	if not is_multiplayer_authority():
		return
	notify_state_changed.rpc(state)

func set_level(l: GameLevel):
	level = l
	hud = get_node("/root/World/CanvasLayer/HUD")
	hud.show()
	THIS_ID = multiplayer.get_unique_id()

func set_money(value: float):
	money = snapped(value, 0.01)
	money_changed.emit(money)
	
	if not is_multiplayer_authority():
		return
	notify_money_changed.rpc(money)

func _ready() -> void:
	register_validator(Phase.OPEN_FOR_BUSINESS, player_validator, "A player is holding something!")

func player_validator() -> bool:
	for player_id in players:
		if players[player_id].holder.is_holding_item() or players[player_id].edit_mode_ray_cast.is_holding_editable:
			return false
	return true

func add_money(value: float):
	set_money(money + value)

func subtract_money(value: float):
	set_money(money - value)

func reset():
	players.clear()
	level = null

func get_player_by_id(p_id: int) -> Player:
	return get_player_by_name(str(p_id))

func get_player_by_name(player_name: String) -> Player:
	return players.get(player_name)

func add_player(player: Player):
	players[player.name] = player
	
	if player.name == str(multiplayer.get_unique_id()):
		player.set_color(player_color)

func remove_player(p_id : int):
	if is_multiplayer_authority():
		cleanup_disconnecting_player.rpc(p_id)
		await get_tree().create_timer(3.0, false).timeout
		if players.get(p_id) != null:
			players[p_id].queue_free()
	
	players.erase(p_id)

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	
	if event is InputEvent and event.is_action_pressed("switch_mode"):
		if state == Phase.OPEN_FOR_BUSINESS:
			state = Phase.EDITING_RESTAURANT
		elif state == Phase.EDITING_RESTAURANT:
			state = Phase.OPEN_FOR_BUSINESS
	if (event.as_text() as String).to_lower() == "m":
		modifiers.max_party_size += 1

@rpc("authority", "call_local")
func cleanup_disconnecting_player(p_id: int):
	var player = get_player_by_id(p_id)
	# Preserve the Item the Disconnecting player was holding
	move_player_held_item_to_spawn(player)

	player.hide()

func move_player_held_item_to_spawn(player: Player) -> void:
	# Preserve the Item the Disconnecting player was holding
	if player.holder.is_holding_item():
		var interactable : Interactable = player.holder.get_held_item()
		interactable.reparent(level)
		interactable.position = level.spawn_point.position
		interactable.rotation = level.spawn_point.rotation
		interactable.enable_collider()

@rpc("authority", "reliable")
func notify_money_changed(value: int):
	set_money(value)

@rpc("authority", "reliable")
func notify_state_changed(value: int):
	state = value as Phase
