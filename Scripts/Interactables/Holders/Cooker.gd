extends Holder
class_name CookerComponent

signal cook_progress(progress: float)

@export var power : float = 0.5

# When cooking multiple items on the same Cooker, incur loss of power
# to encourage individual cooking of items
@export var power_loss_item_count_begin = 2
@export var door_rotatable : Rotatable
@export var cooking_sfx : AudioStream

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

func _on_door_rotated() -> void:
	if door_rotatable.is_rotated:
		stop_cooking()
	else:
		if is_holding_item() and node_is_cookable(get_held_item()):
			begin_cooking()

func can_cook() -> bool:
	var has_door = door_rotatable != null
	if has_door:
		return not door_rotatable.is_rotated
	return true

func node_is_cookable(node: Node3D) -> bool:
	return (node is Cookable or node is MultiHolder or node is CombinedFoodHolder) and can_cook()

func hold_item(node: Node3D):
	super(node)
	if node_is_cookable(node):
		begin_cooking()
	else:
		#print("%s isn't cookable, but i'll hold on to it" % node.name)
		pass

func release_item_to(holder: Holder):
	super(holder)
	stop_cooking()

func begin_cooking():
	tick_timer.start()
	audio_player.play()

func stop_cooking():
	tick_timer.stop()
	if audio_player.playing:
		audio_player.stop()

func _on_cooking_ticks_timer_timeout():
	var cooked = false
	# Cook everything on the Multiholder / CombinedFoodHolders, with power loss per item
	if get_held_item() is MultiHolder or get_held_item() is CombinedFoodHolder:
		var curr_power = power
		var num_cooked = 0
		var multi_h_items : Array[Node] = get_held_item().get_held_items()
		
		for item in multi_h_items:
			if item is Cookable:
				(item as Cookable).cook(curr_power)
				cooked = true
				num_cooked += 1
				if num_cooked >= power_loss_item_count_begin:
					curr_power = clamp(pow(curr_power, 2), 0.1, power)
				
	else:
		for cookable in get_children().filter(func(c): return c is Cookable):
			(cookable as Cookable).cook(power)
			cooked = true
	
	# Keep cookin if there is something to cook
	if cooked:
		tick_timer.start()
