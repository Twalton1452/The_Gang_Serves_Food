class_name Combiner


# Theres a cleaner refactor hidden in here
# Something that handles the types as they come instead of the situations as they happen
# Handling situations requires context as to what happened in the previous parts 
# to understand what is going on in the later parts
# if player holding StackingHolder -> evaluate everything
# if player holding CombinedFoodHolder -> evaluate everything, etc


## When the player is trying to Combine Food spawn a particlar Holder to handle it
## The Food Combiner scene will organize the foods and keep them together
static func combine(player: Player, resting: Holdable):
	# Can't combine without Player holding something for now.. with Automation you could
	if not player.c_holder.is_holding_item():
		return
	
	var resting_p = resting.get_parent()
	var is_exactly_holder = resting_p is Holder and not resting_p is MultiHolder and \
							not resting_p is StackingHolder and not CombinedFoodHolder
	
	# Player is combining with an item on a counter (Simplest Holder)
	if is_exactly_holder:
		Combiner.spawn_combiner(resting_p, player.c_holder)
		return
	
	var player_item = player.c_holder.get_held_item()
	# Don't combine in-hand if Player is holding a Plate or a box of Food
	if player_item is MultiHolder:
		return
	
	# Player is trying to pull off a Multi/Stacking Holder to continue combining in their hand
	if player_item is CombinedFoodHolder:
		# Give from Player's CombinedFood to resting CombinedFood
		if resting_p is CombinedFoodHolder:
			player_item.release_item_to(resting_p)
		# Take from resting holder into Player's CombinedFood
		else:
			resting_p.release_item_to(player_item)
		return
	
	# Player is holding 1 ingredient
	if not player_item is StackingHolder:
		# Player giving to a combination despite having 1 ingredient
		if resting_p is CombinedFoodHolder:
			player.c_holder.release_item_to(resting_p)
		# Player trying to start a combination
		else:
			Combiner.spawn_combiner(player.c_holder, resting_p)

static func spawn_combiner(holder_accepting_item : Holder, holder_giving_up_item : Holder) -> StackingHolder:
	var combiner : StackingHolder = NetworkingUtils.spawn_node(NetworkedScenes.get_scene_by_id(NetworkedIds.Scene.FOOD_COMBINER), MidsessionJoinSyncer)
	
	holder_giving_up_item.release_item_to(combiner)
	holder_accepting_item.release_item_to(combiner)
	holder_accepting_item.hold_item(combiner)
	
	return combiner
				
## When a Food Combination gets down to 1 item, it will call this method
## We need to reparent the 1 item to the parent of the Holder we're destroying
static func destroy_combination(s_holder: CombinedFoodHolder):
	var s_holder_p : Holder = s_holder.get_parent()
	var left_over_item = s_holder.get_held_item()
	
	s_holder.remove_child(left_over_item)
	s_holder_p.add_child(left_over_item, true)
	s_holder.queue_free()
	
