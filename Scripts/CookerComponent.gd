extends HolderComponent
class_name CookerComponent

@export var power : float = 0.5

@onready var tick_timer = $CookingTicksTimer

func hold_item(node: Node3D):
	super(node)
	if node is CookableComponent:
		begin_cooking()
	else:
		#print("%s isn't cookable, but i'll hold on to it" % node.name)
		pass

func release_item_to(holder: HolderComponent):
	super(holder)
	stop_cooking()

func begin_cooking():
	tick_timer.start()

func stop_cooking():
	tick_timer.stop()

func _on_cooking_ticks_timer_timeout():
	for cookable in get_children().filter(func(c): return c is CookableComponent):
		(cookable as CookableComponent).cook(power)
	tick_timer.start()
