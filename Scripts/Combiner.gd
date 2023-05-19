class_name Combiner

# Combine the items into the Player's hand
# Can avoid confusion with Multi/Stacking Holders if every result ends in the Player's hand
static func combine(player: Player, resting: Holdable):
	var in_hand = player.c_holder.get_held_item()
