extends InteractableComponent
class_name HoldableComponent

func set_sync_state(value) -> int:
	var continuing_offset = super(value)
	var is_being_held = bool(value.decode_u8(continuing_offset))
	if is_being_held:
		(get_parent() as HolderComponent).hold_item(self)
	
	return continuing_offset + 1 # + 1 because the u8

func get_sync_state() -> PackedByteArray:
	var buf = super()
	var end_of_parent_buf = buf.size()
	var is_being_held = get_parent() is HolderComponent
	buf.resize(end_of_parent_buf + 1)
	buf.encode_u8(end_of_parent_buf, is_being_held) # u8 is 1 byte
	return buf

func _secondary_interact(player: Player):
	if not player.c_holder.is_holding_item():
		return
	
	var p_item
	if player.c_holder.get_held_item() is MultiHolderComponent:
		if player.c_holder.is_holding_item():
			p_item = player.c_holder.get_held_item().get_held_item()
		else:
			return
	else:
		p_item = player.c_holder.get_held_item()
	FoodCombiner.combine(self, p_item)
