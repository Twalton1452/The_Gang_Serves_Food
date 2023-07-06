extends Node3D
class_name PowerConsumer

## Class to inherit from for Nodes that would draw from the PowerGrid
## Override [_power_dependent_action() -> void] and when enough power is available it will execute the action
## Call using [power_dependent_action() -> bool] to consume power

@export var consumption_per_action = 1.0

@onready var power_sprite : Sprite3D = $PowerSprite3D

## When the PowerGrid is struggling,
## the Consumer will try and take as much as possible in order to perform the action
var accumulated_power = 0.0

func set_sync_state(reader: ByteReader) -> void:
	accumulated_power = reader.read_float()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_float(accumulated_power)
	return writer

func _power_dependent_action() -> void:
	pass

func _ready():
	power_sprite.hide()

## Consume as much power to perform the action as possible
## If not enough power was consumed then it will hold that power for the next cycle
## returns true if performed the dependent action
func power_dependent_action() -> bool:
	accumulated_power += PowerGrid.draw_from(consumption_per_action)
	if accumulated_power >= consumption_per_action:
		accumulated_power -= consumption_per_action
		_power_dependent_action()
		hide_low_power()
		return true
	display_low_power()
	return false

func display_low_power() -> void:
	power_sprite.show()

func hide_low_power() -> void:
	power_sprite.hide()
