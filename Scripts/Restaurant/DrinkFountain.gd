extends Node3D
class_name DrinkFountain

@export var fill_rate = 0.1
@export var shut_off_dispenser_on_filled = true

@onready var dispensers_root = $FountainModel
@onready var fill_rate_timer : Timer = $FillRateTimer

var dispensers : Array[DrinkDispenser] = []

func set_sync_state(reader: ByteReader) -> void:
	var is_timer_playing = reader.read_bool()
	if is_timer_playing:
		# Instead of setting the timer to this tick rate and then adding logic to 
		# set it back after the tick, just simulate a tick
		var time_left = reader.read_small_float()
		await get_tree().create_timer(time_left, false).timeout
		_on_fill_rate_tick()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	var is_timer_playing = not fill_rate_timer.is_stopped()
	writer.write_bool(is_timer_playing)
	if is_timer_playing:
		writer.write_small_float(fill_rate_timer.time_left)
	return writer

func _ready():
	fill_rate_timer.timeout.connect(_on_fill_rate_tick)
	for child in dispensers_root.get_children():
		if child is DrinkDispenser:
			var dispenser : DrinkDispenser = child
			dispensers.push_back(dispenser)
			dispenser.holding_drink.connect(_on_drink_dispenser_activated)
			dispenser.released_drink.connect(_on_drink_left_dispenser_zone)

func _on_drink_dispenser_activated(_dispenser: DrinkDispenser) -> void:
	if fill_rate_timer.is_stopped():
		fill_rate_timer.start()

func _on_drink_left_dispenser_zone(_dispenser: DrinkDispenser) -> void:
	if dispensers.all(func(d): return not d.activated):
		fill_rate_timer.stop()

func _on_fill_rate_tick():
	for dispenser in dispensers:
		if dispenser.activated:
			var drink : Drink = dispenser.holder.get_held_item()
			if drink.fill_state == Drink.FillState.FILLED and shut_off_dispenser_on_filled:
				dispenser.activated = false
				continue
			
			drink.fill(fill_rate, dispenser.beverage)
	
	fill_rate_timer.start()
