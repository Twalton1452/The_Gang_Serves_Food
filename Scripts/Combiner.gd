class_name Combiner

## When the player is trying to Combine Food spawn a particlar Holder to handle it
## The Food Combiner scene will organize the foods and keep them together
static func combine(player: Player, resting: Holdable):
	# Can't combine without Player holding something for now.. with Automation you could
	if not player.c_holder.is_holding_item():
		return
	
	var resting_p = resting.get_parent()
	var is_exactly_holder = resting_p is Holder and not resting_p is MultiHolder and not resting_p is StackingHolder
	
	# Player is combining with an item on a counter (Simple Holder)
	if is_exactly_holder:
		var combiner : StackingHolder = load("res://Scenes/components/food_combiner.tscn").instantiate()
		var networked_node : NetworkedNode3D = combiner.get_node("NetworkedNode3D")
		
		networked_node.changed = true
		
		resting_p.release_item_to(combiner)
		resting_p.hold_item(combiner)
		player.c_holder.release_item_to(combiner)
	# Don't combine in-hand if Player is holding a Plate or a box of Food
	elif not player.c_holder.get_held_item() is MultiHolder:
		# Player has 1 ingredient and trying to start a combination
		if not player.c_holder.get_held_item() is StackingHolder:
			var combiner : StackingHolder = load("res://Scenes/components/food_combiner.tscn").instantiate()
			var networked_node : NetworkedNode3D = combiner.get_node("NetworkedNode3D")
			
			networked_node.changed = true
			
			resting_p.release_item_to(combiner)
			player.c_holder.release_item_to(combiner)
			player.c_holder.hold_item(combiner)
		# Player is trying to pull off a Multi/Stacking Holder to continue combining in their hand
		# TODO: Refactor StackingHolder here to be "CombinerHolder" or something
		elif player.c_holder.get_held_item() is StackingHolder and player.c_holder.get_held_item().destroy_on_empty:
			resting_p.release_item_to(player.c_holder.get_held_item())
		

## When a Food Combination gets down to 1 item, it will call this method
## We need to reparent the 1 item to the parent of the Holder we're destroying
static func destroy_combination(s_holder: StackingHolder):
	var s_holder_p : Holder = s_holder.get_parent()
	var left_over_item = s_holder.get_held_item()
	
	s_holder.remove_child(left_over_item)
	s_holder_p.add_child(left_over_item, true)
	s_holder.queue_free()
	
