class_name Combiner

static func combine(player: Player, resting: Holdable):
	var resting_p = resting.get_parent()
	var is_exactly_holder = resting_p is Holder and not resting_p is MultiHolder and not resting_p is StackingHolder
	if is_exactly_holder and player.c_holder.is_holding_item():
		var combinor : StackingHolder = load("res://Scenes/components/food_combiner.tscn").instantiate()
		var networked_node : NetworkedNode3D = combinor.get_node("NetworkedNode3D")
		
		networked_node.changed = true
		
		resting_p.release_item_to(combinor)
		resting_p.hold_item(combinor)
		player.c_holder.release_item_to(combinor)

static func destroy_combination(s_holder: StackingHolder):
	var s_holder_p : Holder = s_holder.get_parent()
	var left_over_item = s_holder.get_held_item()
	
	s_holder.remove_child(left_over_item)
	s_holder_p.add_child(left_over_item, true)
	s_holder.queue_free()
	
