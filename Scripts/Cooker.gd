extends Holder
class_name CookerComponent

@export var power : float = 0.5

# When cooking multiple items on the same Cooker, incur loss of power
# to encourage individual cooking of items
@export var power_loss_item_count_begin = 2

@onready var tick_timer = $CookingTicksTimer


func hold_item(node: Node3D):
	super(node)
	if node is Cookable or node is MultiHolder or node is CombinedFoodHolder:
		begin_cooking()
	else:
		#print("%s isn't cookable, but i'll hold on to it" % node.name)
		pass

func release_item_to(holder: Holder):
	super(holder)
	stop_cooking()

func begin_cooking():
	tick_timer.start()

func stop_cooking():
	tick_timer.stop()

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
