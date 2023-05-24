class_name Combiner

## When the player is trying to Combine Food spawn a particlar Holder to handle it
## The Food Combiner scene will organize the foods and keep them together
static func combine(player: Player, resting: Holdable):
	# Can't combine without Player holding something for now.. with Automation you could
	if not player.c_holder.is_holding_item():
		return
	
	var resting_p = resting.get_parent()
	var is_exactly_holder = resting_p is Holder and not resting_p is MultiHolder and \
							not resting_p is StackingHolder and not CombinedFoodHolder
	
	# Player is combining with an item on a counter (Simple Holder)
	if is_exactly_holder:
		spawn_combiner(resting_p, player.c_holder)
	# Don't combine in-hand if Player is holding a Plate or a box of Food
	elif not player.c_holder.get_held_item() is MultiHolder:
		# Player is trying to pull off a Multi/Stacking Holder to continue combining in their hand
		if player.c_holder.get_held_item() is CombinedFoodHolder:
			# Give from Player's CombinedFood to resting CombinedFood
			if resting_p is CombinedFoodHolder:
				player.c_holder.get_held_item().release_item_to(resting_p)
			# Take from resting holder into Player's CombinedFood
			else:
				resting_p.release_item_to(player.c_holder.get_held_item())
		# Player is holding 1 ingredient
		elif not player.c_holder.get_held_item() is StackingHolder:
			# Player giving to a combination despite having 1 ingredient
			if resting_p is CombinedFoodHolder:
				player.c_holder.release_item_to(resting_p)
			# Player trying to start a combination
			else:
				spawn_combiner(player.c_holder, resting_p)

static func spawn_combiner(holder_for_combination : Holder, holder_giving_up_item : Holder) -> StackingHolder:
	var combiner : StackingHolder = load("res://Scenes/components/food_combiner.tscn").instantiate()
	var networked_node : NetworkedNode3D = combiner.get_node("NetworkedNode3D")
	
	holder_giving_up_item.release_item_to(combiner)
	holder_for_combination.release_item_to(combiner)
	holder_for_combination.hold_item(combiner)
	
	networked_node.generated_at_run_time_setup()
	return combiner
				
## When a Food Combination gets down to 1 item, it will call this method
## We need to reparent the 1 item to the parent of the Holder we're destroying
static func destroy_combination(s_holder: CombinedFoodHolder):
	var s_holder_p : Holder = s_holder.get_parent()
	var left_over_item = s_holder.get_held_item()
	
	s_holder.remove_child(left_over_item)
	s_holder_p.add_child(left_over_item, true)
	s_holder.queue_free()
	
