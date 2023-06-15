extends Node

## Autoloaded

signal state_changed
signal money_changed(value: float)

var SERVER_ID = 1
var THIS_ID = -1

enum Phase {
	LOBBY,
	EDITING_RESTAURANT,
	OPEN_FOR_BUSINESS,
}

var state : Phase = Phase.OPEN_FOR_BUSINESS : set = set_state

var players : Dictionary = {}
var level : Level : set = set_level
var hud : HUD = null

var money : float = 0.0 # Good use case for "Watched" Property in Godot 4.1

var multiholder_multiplier : float = 1.5
var combined_food_multiplier : float = 1.5 ## multiply per food in the stack

func set_sync_state(reader: ByteReader):
	set_money(reader.read_float())

func get_sync_state() -> ByteWriter:
	var writer : ByteWriter = ByteWriter.new()
	writer.write_float(money)
	return writer

func set_state(value: Phase):
	state = value
	state_changed.emit()

func set_level(l: Level):
	level = l
	hud = get_node("/root/World/CanvasLayer/HUD")
	THIS_ID = multiplayer.get_unique_id()

func set_money(value: float):
	money = snapped(value, 0.01)
	money_changed.emit(money)
	if is_multiplayer_authority():
		notify_money_changed.rpc(money)

func add_money(value: float):
	set_money(money + value)

func subtract_money(value: float):
	set_money(money - value)

func reset():
	players.clear()
	level = null

func get_player_by_id(p_id: int) -> Player:
	return players.get(str(p_id))

func add_player(player: Player):
	players[player.name] = player

func remove_player(p_id : int):
	if is_multiplayer_authority():
		cleanup_disconnecting_player.rpc(p_id)
		await get_tree().create_timer(3.0).timeout
		if players.get(p_id) != null:
			players[p_id].queue_free()
	
	players.erase(p_id)

@rpc("authority", "call_local")
func cleanup_disconnecting_player(p_id: int):
	var player = get_player_by_id(p_id)
	# Preserve the Item the Disconnecting player was holding
	if player.holder.is_holding_item():
		var interactable : Interactable = player.holder.get_held_item()
		interactable.reparent(level)
		interactable.position = level.spawn_point.position
		interactable.rotation = level.spawn_point.rotation
		interactable.enable_collider()

	player.hide()

@rpc("authority", "reliable")
func notify_money_changed(value: int):
	set_money(value)
