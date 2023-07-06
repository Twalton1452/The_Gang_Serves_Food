extends Node3D
class_name PowerGenerator

const GENERATOR_GROUP = "Generators"

@export var potential_power_per_tick = 1.0
@export var capacity = 100.0

@onready var power_bar_visual : WorldProgressBar = $HorizontalProgressBar

var stored_amount = 0.0 : set = set_stored_amount

func set_sync_state(reader: ByteReader):
	stored_amount = reader.read_float()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_float(stored_amount)
	return writer

func set_stored_amount(value: float) -> void:
	stored_amount = value
	power_bar_visual.update(stored_amount / capacity)

func _ready() -> void:
	add_to_group(GENERATOR_GROUP)
	stored_amount = capacity

## Called from Autoloaded PowerGrid.gd, passing the tick_rate in seconds
## So if we ever decide to change the tick rate to be faster or slower
## we won't need to adjust every PowerGenerator's value
func tick(tick_rate_seconds: float) -> void:
	stored_amount += potential_power_per_tick * tick_rate_seconds
	if stored_amount > capacity:
		stored_amount = capacity

func consume(amount: float) -> float:
	var amount_left = stored_amount - amount
	if amount_left < 0:
		# Extract the last of it
		if stored_amount > 0:
			var difference = abs(amount_left)
			stored_amount = 0.0
			return difference
		return 0.0
	
	stored_amount -= amount
	return amount
