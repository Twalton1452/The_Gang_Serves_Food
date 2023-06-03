extends Node

## Autoloaded

signal money_changed(value: float)

var SERVER_ID = 1

enum Phase {
	EDITING_RESTAURANT,
	OPEN_FOR_BUSINESS,
}

var state : Phase = Phase.OPEN_FOR_BUSINESS

var players : Array[Player] = []
var level : Level : set = set_level
var hud : HUD = null

var money : float = 0.0 : set = add_money # Good use case for "Watched" Property in Godot 4.1

func set_level(l: Level):
	level = l
	hud = get_node("/root/World/CanvasLayer/HUD")

func add_money(value: float):
	money += value
	money_changed.emit(money)

func reset():
	players.clear()
	level = null

func get_player_by_id(p_id: int) -> Player:
	for p in players:
		if p.name.to_int() == p_id:
			return p
	return null

func add_player(player: Player):
	players.push_back(player)

func remove_player(p_id : int):
	var i = 0
	for p in players:
		if p.name.to_int() == p_id:
			break
		i += 1
	players[i].hide()
	
	if is_multiplayer_authority():
		cleanup_disconnecting_player.rpc(p_id)
		await get_tree().create_timer(3.0).timeout
		if i < players.size() and players[i] != null:
			players[i].queue_free()
	
	players.remove_at(i)

@rpc("call_local")
func cleanup_disconnecting_player(p_id: int):
	var player = get_player_by_id(p_id)
	# Preserve the Item the Disconnecting player was holding
	if player.c_holder.is_holding_item():
		var interactable : Interactable = player.c_holder.get_held_item()
		interactable.reparent(level)
		interactable.position = level.spawn_point.position
		interactable.rotation = level.spawn_point.rotation
		interactable.enable_collider()

	player.hide()
	
