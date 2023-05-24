extends Node

## Autoloaded

var players : Array[Player] = []
var level : Level : set = set_level

func set_level(l: Level):
	level = l

func reset():
	players.clear()
	level = null

func add_player(player : Player):
	players.push_back(player)

func remove_player(p_id : int):
	var i = 0
	for p in players:
		if p.name.to_int() == p_id:
			break
		i += 1
	if players[i].c_holder.is_holding_item():
		var path = StringName(players[i].c_holder.get_held_item().get_path()).to_utf32_buffer()
		preserve_player_held_item.rpc(path)
	players.remove_at(i)

@rpc("call_local")
func preserve_player_held_item(path_to_item : PackedByteArray):
	var interactable : Interactable = get_node(path_to_item.get_string_from_utf32())
	interactable.reparent(level)
	interactable.position = level.spawn_point.position
	interactable.rotation = level.spawn_point.rotation
	interactable.enable_collider()

func get_player_by_id(p_id: int) -> Player:
	for p in players:
		if p.name.to_int() == p_id:
			return p
	return null
