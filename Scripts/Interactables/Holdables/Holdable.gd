extends Interactable
class_name Holdable
	
func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	var is_being_held = reader.read_bool()
	if is_being_held:
		(get_parent() as Holder).hold_item(self)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	var is_being_held = get_parent() is Holder
	writer.write_bool(is_being_held)
	return writer

func _interact(player: Player):
	# Item free floating, just take it
	if not get_parent() is Holder:
		player.c_holder.hold_item(self)
	# Let the Holder take care of the interaction
	else:
		(get_parent() as Holder).interact(player)

func _secondary_interact(player: Player):
	# Player trying to take wherever this thing is
	if not player.c_holder.is_holding_item():
		if get_parent() is Holder:
			(get_parent() as Holder).release_this_item_to(self, player.c_holder)
		return
	
	# Get the Player's item to see if we can Combine!
	# Don't combine off a MultiHolder in the Player's Hand because that could get weird fast
	if not player.c_holder.get_held_item() is MultiHolder:
		Combiner.combine(player, self)
	# If combination can't take place, maybe a standard secondary interaction can
	elif get_parent() is Holder:
		(get_parent() as Holder).secondary_interact(player)
