extends Resource
class_name Power

@export var amount : float = 0.0
var max_amount = 1000000.0

func set_to(value: float) -> void:
	amount = value

func store(value: float) -> void:
	if amount > max_amount:
		return
	amount += value

func consume(value: float) -> void:
	amount -= value
