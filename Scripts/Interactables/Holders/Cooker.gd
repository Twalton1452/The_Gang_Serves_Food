extends Holder
class_name CookerComponent

@export var power : float = 0.5

# When cooking multiple items on the same Cooker, incur loss of power
# to encourage individual cooking of items
@export var power_loss_item_count_begin = 2
@export var door_rotatable : Rotatable
@export var cooking_sfx : AudioStream
@export var progress_bar_visual : WorldProgressBar

@onready var tick_timer : Timer = $CookingTicksTimer
@onready var audio_player : AudioStreamPlayer3D = $AudioStreamPlayer3D

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	var is_timer_playing = reader.read_bool()
	if is_timer_playing:
		# Instead of setting the Timer Node to this tick rate and then adding logic to 
		# set it back to its original tick rate, just simulate a tick
		var time_left = reader.read_small_float()
		await get_tree().create_timer(time_left, false).timeout
		progress_bar_visual.show_visual()
		_on_cooking_ticks_timer_timeout()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	var is_timer_playing = not tick_timer.is_stopped()
	writer.write_bool(is_timer_playing)
	if is_timer_playing:
		writer.write_small_float(tick_timer.time_left)
	return writer

func _ready() -> void:
	super()
	if door_rotatable != null:
		door_rotatable.rotated.connect(_on_door_rotated)
	audio_player.stream = cooking_sfx
	
	if progress_bar_visual == null:
		for child in get_children():
			if child is WorldProgressBar:
				progress_bar_visual = child
				break
	progress_bar_visual.hide_visual()
	progress_bar_visual.time_between_ticks = tick_timer.wait_time

func can_cook() -> bool:
	var has_door = door_rotatable != null
	if has_door:
		return not door_rotatable.is_rotated
	return get_cookables().size() > 0

func _on_door_rotated() -> void:
	if door_rotatable.is_rotated:
		stop_cooking()
	elif can_cook():
		begin_cooking()

func hold_item(node: Node3D):
	super(node)
	if can_cook():
		begin_cooking()

func release_item_to(holder: Holder):
	super(holder)
	stop_cooking()

func begin_cooking():
	var cookables = get_cookables()
	if cookables.size() == 0:
		return
	
	progress_bar_visual.show_visual((cookables.front() as Cookable).cook_progress)
	tick_timer.start()
	audio_player.play()

func stop_cooking():
	progress_bar_visual.hide_visual()
	tick_timer.stop()
	if audio_player.playing:
		audio_player.stop()

## Checks the held items for anything that can be cooked and isn't already burned
func get_cookables() -> Array[Node]:
	if not is_holding_item():
		return []
	var held_item = get_held_item()
	if held_item is Cookable and held_item.cook_state != Cookable.CookState.BURNED:
		return [held_item]
	if held_item is MultiHolder or held_item is CombinedFoodHolder:
		return held_item.get_held_items().filter(func(held): return held is Cookable and held.cook_state != Cookable.CookState.BURNED)
	else:
		return get_children().filter(func(c): return c is Cookable and c.cook_state != Cookable.CookState.BURNED)

func _on_cooking_ticks_timer_timeout():
	# Cook everything on the Multiholder / CombinedFoodHolders, with power loss per item
	var curr_power = power
	var num_cooked = 0
	var cookables = get_cookables() as Array[Cookable]
	var still_cookable = false
	
	for cookable in cookables:
		cookable.cook(curr_power)
		if cookable.cook_state != Cookable.CookState.BURNED:
			still_cookable = true
		
		num_cooked += 1
		if num_cooked >= power_loss_item_count_begin:
			curr_power = clamp(pow(curr_power, 2), 0.1, power)
	
	# Keep cookin if there is something to cook
	if still_cookable:
		tick_timer.start()
		progress_bar_visual.update(cookables.front().cook_progress)
	else:
		stop_cooking()
