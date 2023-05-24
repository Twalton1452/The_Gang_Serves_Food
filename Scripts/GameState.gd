extends Node

## Autoloaded

var players : Array[Player] = []
var level : Level : set = set_level

func set_level(l: Level):
	level = l

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
