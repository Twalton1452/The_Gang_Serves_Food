extends Node

## Autoloaded

## Class to handle all of the RPC's related to Accumulator spawning

var timer : Timer
var tick_rate_seconds = 1.0

func _ready():
	# For Autoload's this isn't reliable because authority is set after the player connects
	if not is_multiplayer_authority():
		return
	
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_tick)
	
	GameState.state_changed.connect(_on_game_state_changed)
	_on_game_state_changed()

func _on_game_state_changed():
	if not is_multiplayer_authority():
		return
	
	if GameState.state == GameState.Phase.OPEN_FOR_BUSINESS:
		timer.start(tick_rate_seconds)
	else:
		timer.stop()

func _on_tick():
	if not is_multiplayer_authority():
		return
	
	notify_tick.rpc()

@rpc("authority", "call_local")
func notify_tick():
	get_tree().call_group(Accumulator.ACCUMULATOR_GROUP, "accumulate")
