extends Interactable
class_name Holdable

func set_sync_state(value) -> int:
	var continuing_offset = super(value)
	var is_being_held = bool(value.decode_u8(continuing_offset))
	if is_being_held:
		(get_parent() as Holder).hold_item(self)
	
	return continuing_offset + 1 # + 1 because the u8

func get_sync_state() -> PackedByteArray:
	var buf = super()
	var end_of_parent_buf = buf.size()
	var is_being_held = get_parent() is Holder
	buf.resize(end_of_parent_buf + 1)
	buf.encode_u8(end_of_parent_buf, is_being_held) # u8 is 1 byte
	return buf

func _interact(player: Player):
	# Item free floating, just take it
	if not get_parent() is Holder:
		player.c_holder.hold_item(self)
		return
		
	# Player not holding anything - Take this item
	if not player.c_holder.is_holding_item():
		get_parent().release_item_to(player.c_holder)
	# Put this Item onto the Player's MultiHolder
	elif player.c_holder.get_held_item() is MultiHolder:
		get_parent().release_item_to(player.c_holder.get_held_item())
	# Swap Items if there is something on both sides
	elif get_parent().is_holding_item() and player.c_holder.get_held_item() is Holdable:
		player.c_holder.swap_items_with(get_parent())

func _secondary_interact(player: Player):
	if not player.c_holder.is_holding_item():
		return
	
	
	var p_item
	# Player holding Plate
	if player.c_holder.get_held_item() is MultiHolder:
		# Something on the Plate
		if player.c_holder.is_holding_item():
			p_item = player.c_holder.get_held_item().get_held_item()
		else:
			return
	else:
		p_item = player.c_holder.get_held_item()
	
	if get_parent() is StackingHolder and p_item != null:
		get_parent().hold_item(p_item)
		return
		
	FoodCombiner.combine(self, p_item)
