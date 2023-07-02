extends Node

## Autoloaded

## Class to handle all of the RPC's related to Accumulator spawning

func accumulate(accumulator: Accumulator) -> void:
	if not is_multiplayer_authority():
		return
	
	if accumulator.to_accumulate_scene == null or not accumulator.holder.has_space_for_another_item():
		return
	
	var accumlated_node = NetworkingUtils.spawn_node_for_everyone(accumulator.to_accumulate_scene, self)
	accumulator.holder.hold_item(accumlated_node)
	
	var writer = ByteWriter.new()
	writer.write_path_to(accumulator)
	writer.write_str(accumlated_node.name)
	notify_peers_of_accumulation.rpc(writer.data)

@rpc("authority", "call_remote", "reliable")
func notify_peers_of_accumulation(data: PackedByteArray) -> void:
	var reader = ByteReader.new(data)
	var accumulator : Accumulator = get_node(reader.read_path_to())
	var accumulated_node = get_node(reader.read_str())
	accumulator.holder.hold_item(accumulated_node)

#var timer : Timer
#var tick_rate_seconds = 1.0
#
#func _ready():
#	# For Autoload's this isn't reliable because authority is set after the player connects
#	if not is_multiplayer_authority():
#		return
#
#	timer = Timer.new()
#	add_child(timer)
#	timer.timeout.connect(_on_tick)
#
#	GameState.state_changed.connect(_on_game_state_changed)
#	_on_game_state_changed()
#
#func _on_game_state_changed():
#	if not is_multiplayer_authority():
#		return
#
#	if GameState.state == GameState.Phase.OPEN_FOR_BUSINESS:
#		timer.start(tick_rate_seconds)
#	else:
#		timer.stop()
#
#func _on_tick():
#	if not is_multiplayer_authority():
#		return
#
#	notify_tick.rpc()
#
#@rpc("authority", "call_local")
#func notify_tick():
#	get_tree().call_group(Accumulator.ACCUMULATOR_GROUP, "accumulate")
