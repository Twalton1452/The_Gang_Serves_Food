extends Node

## Autoloaded

var players : Array[Player] = []

func reset():
	players.clear()

func add_player(player : Player):
	players.push_back(player)

func remove_player(p_id : int):
	var i = 0
	for p in players:
		if p.name.to_int() == p_id:
			break
		i += 1
	players.remove_at(i)

func get_player_by_id(p_id: int) -> Player:
	for p in players:
		if p.name.to_int() == p_id:
			return p
	return null
