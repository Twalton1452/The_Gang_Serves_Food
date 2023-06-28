extends Node3D
class_name Accumulator

@export var to_accumulate_scene : PackedScene : set = set_to_accumulate_scene

@onready var display = $Display
@onready var accumulate_timer = $AccumulateTimer

const ACCUMULATOR_GROUP = "Accumulators"

var holder : StackingHolder = null

func set_sync_state(reader: ByteReader) -> void:
	var is_timer_playing = reader.read_bool()
	if is_timer_playing:
		# Instead of setting the Timer Node to this tick rate and then adding logic to 
		# set it back to its original tick rate, just simulate a tick
		var time_left = reader.read_small_float()
		await get_tree().create_timer(time_left, false).timeout
		_on_accumulate_timer_tick()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	var is_timer_playing = not accumulate_timer.is_stopped()
	writer.write_bool(is_timer_playing)
	if is_timer_playing:
		writer.write_small_float(accumulate_timer.time_left)
	return writer

func set_to_accumulate_scene(value: PackedScene) -> void:
	to_accumulate_scene = value
	
	# Side effect of using @export, calls the setter before _ready occurs
	# Without this display/holder are null
	if not is_inside_tree():
		await ready
	
	display.add_child(to_accumulate_scene.instantiate())
	holder.ingredient_scene = to_accumulate_scene

func _ready() -> void:
	accumulate_timer.timeout.connect(_on_accumulate_timer_tick)
	GameState.state_changed.connect(_on_game_state_changed)
	display.child_entered_tree.connect(_on_node_entered_display_tree)
	for child in get_children():
		if child is StackingHolder:
			holder = child
			break
	_on_game_state_changed()

func _on_game_state_changed():
	if GameState.state == GameState.Phase.OPEN_FOR_BUSINESS:
		accumulate_timer.start()
	else:
		accumulate_timer.stop()

func _on_node_entered_display_tree(node: Node) -> void:
	node.propagate_call("set_collision_layer_value", [Interactable.INTERACTABLE_LAYER, false], true)
	node.propagate_call("set_collision_layer_value", [Player.WORLD_MASK, false], true)

func _on_accumulate_timer_tick() -> void:
	accumulate()
	accumulate_timer.start()

## Called from Autoloaded NetworkedAccumlatorManager.gd
func accumulate() -> void:
	if to_accumulate_scene == null or not holder.has_space_for_another_item():
		return
	
	var accumlated_node = to_accumulate_scene.instantiate()
	holder.hold_item(accumlated_node)
	
	# Safeguard for if a player were to put something on the stack while it was spawning
	if not holder.is_holding(accumlated_node):
		print_debug("Accumulator %s for %s spawned, but couldn't fit another. Deleting it" % [name, to_accumulate_scene.resource_name])
		accumlated_node.queue_free()
