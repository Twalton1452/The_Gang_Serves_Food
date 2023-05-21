class_name Combiner

# Combine the items into the Player's hand
# Can avoid confusion with Multi/Stacking Holders if every result ends in the Player's hand
static func combine(player: Player, resting: Holdable):
	#var in_hand = player.c_holder.get_held_item()
	var resting_p = resting.get_parent()
	var is_exactly_holder = resting_p is Holder and not resting_p is MultiHolder and not resting_p is StackingHolder
	if is_exactly_holder and player.c_holder.is_holding_item():
		var combinor : StackingHolder = load("res://Scenes/components/stacking_holder.tscn").instantiate()
		var networked_node : NetworkedNode3D = load("res://Scenes/networked_node_3d.tscn").instantiate()
		combinor.add_child(networked_node, true)
		combinor.is_organized = true
		networked_node.changed = true
		
		resting_p.release_item_to(combinor)
		resting_p.hold_item(combinor)
		player.c_holder.release_item_to(combinor)
		
		print(combinor.get_held_items())
		for item in combinor.get_held_items():
			print(item.position)

static func destroy_combination(s_holder: StackingHolder):
	var s_holder_p : Holder = s_holder.get_parent()
	var left_over_item = s_holder.get_held_item()
	
	s_holder.remove_child(left_over_item)
	s_holder.queue_free()
	
	s_holder_p.hold_item(left_over_item)
