extends Interactable
class_name Holdable
	
func _interact(player: Player):
	# Item free floating, just take it
	if not get_parent() is Holder:
		player.holder.hold_item(self)
	# Let the Holder take care of the interaction
	else:
		(get_parent() as Holder).interact(player)

func _secondary_interact(player: Player):
	# Player trying to take wherever this thing is
	if not player.holder.is_holding_item():
		if get_parent() is Holder:
			(get_parent() as Holder).release_this_item_to(self, player.holder)
		return
	
	if get_parent() is Holder:
		(get_parent() as Holder).secondary_interact(player)
