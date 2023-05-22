extends StackingHolder
class_name CombinedFoodHolder

func _ready():
	stack_items()

func release_item_to(holder: Holder):
	super(holder)
	if len(get_held_items()) == 1:
		Combiner.destroy_combination(self)

func release_this_item_to(item: Node3D, holder: Holder):
	super(item, holder)
	if len(get_held_items()) == 1:
		Combiner.destroy_combination(self)

func stack_items():
	var held_items = get_held_items()
	if len(held_items) == 0:
		return
	
	# Check for everything to be organizable first
	for held_item in held_items:
		if not held_item is Food:
			return
	
	# Sort according to the Rule's set in the Editor for that Scene
	(held_items as Array[Food]).sort_custom(func(a,b):
		if a.rule < b.rule:
			return 1
		return 0
	)
	
	# Establish a base
	# move_child doesn't really matter too much, because Holders 
	# currently put and take from the last available object which auto-organizes it
	move_child(held_items[0], 0)
	held_items[0].position = Vector3.ZERO
	
	# Move the rest of the children according to the newly sorted array
	var i : int = 1
	while i < len(held_items):
		var held_item = held_items[i]
		move_child(held_item, i)
		held_item.position = held_items[i - 1].position + held_items[i - 1].stacking_spacing
		i += 1
	
func _interact(player: Player):
	# Item free floating, just take it
	if not get_parent() is Holder:
		player.c_holder.hold_item(self)
	# Let the Holder take care of the interaction
	else:
		(get_parent() as Holder).interact(player)
