extends Node3D
class_name CookerComponent

@export var power : float = 0.5

@onready var tick_timer = $CookingTicksTimer

var node_to_cook : CookableComponent

func _on_holder_component_started_holding(node: Node3D):
	node_to_cook = node.get_node("CookableComponent")
	begin_cooking()

func _on_holder_component_released_holding(_node: Node3D):
	stop_cooking()
	node_to_cook = null

func begin_cooking():
	tick_timer.start()

func stop_cooking():
	tick_timer.stop()

func _on_cooking_ticks_timer_timeout():
	node_to_cook.cook(power)
	tick_timer.start()
