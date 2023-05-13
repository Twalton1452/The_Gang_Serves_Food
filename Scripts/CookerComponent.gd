extends Node3D
class_name CookerComponent

@export var power : float = 0.5

@onready var tick_timer = $CookingTicksTimer

var node_to_cook : CookableComponent

func _ready():
	var connector : HolderComponent = $"../HolderComponent" if get_node_or_null("../HolderComponent") != null else get_parent()
	connector.started_holding.connect(_on_holder_component_started_holding)
	connector.released_holding.connect(_on_holder_component_released_holding)

# This can get called if the Cooker is reparented
# Need a better method of disconnecting, like a "del" method
func _exit_tree():
	var connector : HolderComponent = $"../HolderComponent" if get_node_or_null("../HolderComponent") != null else get_parent()
	if connector != null:
		connector.started_holding.disconnect(_on_holder_component_started_holding)
		connector.released_holding.disconnect(_on_holder_component_released_holding)

func _on_holder_component_started_holding(node: Node3D):
	if node is CookableComponent:
		node_to_cook = node
		begin_cooking()
	else:
		#print("%s isn't cookable, but i'll hold on to it" % node.name)
		pass

func _on_holder_component_released_holding(_ode: Node3D):
	stop_cooking()
	node_to_cook = null

func begin_cooking():
	tick_timer.start()

func stop_cooking():
	tick_timer.stop()

func _on_cooking_ticks_timer_timeout():
	node_to_cook.cook(power)
	tick_timer.start()
