extends Node3D
class_name DrinkFountain

@export var fill_rate = 0.1

@onready var dispenser_holder : Holder = $DispenserPlatform/Holder
@onready var fill_rate_timer : Timer = $FillRateTimer

var filling_drink : Drink = null

func set_sync_state(reader: ByteReader) -> void:
	var is_timer_playing = reader.read_bool()
	if is_timer_playing:
		# Instead of setting the timer to this tick rate and then adding logic to 
		# set it back after the tick, just simulate a tick
		var time_left = reader.read_small_float()
		await get_tree().create_timer(time_left).timeout
		_on_fill_rate_tick()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	var is_timer_playing = not fill_rate_timer.is_stopped()
	writer.write_bool(is_timer_playing)
	if is_timer_playing:
		writer.write_small_float(fill_rate_timer.time_left)
	return writer

func _ready():
	dispenser_holder.holding_item.connect(_on_item_entered_dispenser_zone)
	dispenser_holder.released_item.connect(_on_item_left_dispenser_zone)
	fill_rate_timer.timeout.connect(_on_fill_rate_tick)

func _on_item_entered_dispenser_zone(item: Node3D) -> void:
	if not item is Drink:
		return
	filling_drink = item
	fill_rate_timer.start()

func _on_item_left_dispenser_zone(_item: Node3D) -> void:
	fill_rate_timer.stop()
	filling_drink = null

func _on_fill_rate_tick():
	if filling_drink == null:
		return
	
	filling_drink.fill(fill_rate)
	fill_rate_timer.start()
