extends Interactable
class_name Holder

@export var can_hold_holders = true

func get_held_items() -> Array[Node]:
	if get_child_count() > 0:
		return get_children().filter(func(c): return c is Holdable or c is Holder)
	return []

func has_space_for_item(_item: Node3D) -> bool:
	return len(get_held_items()) == 0

func is_holding_item() -> bool:
	return len(get_held_items()) > 0

func get_held_item() -> Node3D:
	if is_holding_item():
		return get_held_items()[-1]
	return null

func is_holding(item: Node3D):
	if not is_holding_item():
		return false
	for child in get_children():
		if child == item:
			return true

func hold_item(item: Node3D) -> void:
	if item == null or not has_space_for_item(item) or (item is Holder and not can_hold_holders):
		return
	
	hold_item_unsafe(item)

func hold_item_unsafe(item: Node3D) -> void:
	if not item.is_inside_tree():
		add_child(item, true)
	elif not is_holding(item):
		item.reparent(self, false)
	item.position = Vector3.ZERO

func release_item_to(holder: Holder):
	var item = get_held_item()
	holder.hold_item(item)
	
func swap_items_with(holder: Holder):
	# Causing issues with a combination of a MultiHolder that has multiple StackingHolders
	# Infinitely taking from them, but not giving
	# Happens when you interact with the MultiHolder itself with an item in your hand
	if self is MultiHolder or get_held_item() is MultiHolder or holder.get_held_item() is MultiHolder:
		print_verbose("[NYI] No Swapping for MultiHolders")
		return
	
	var curr_item = get_held_item()
	var holder_item = holder.get_held_item()

	holder.hold_item_unsafe(curr_item)
	hold_item_unsafe(holder_item)

# Left Clicking Holder
func _interact(player : Player):
	# Player placing Item
	if player.c_holder.is_holding_item():
		# This Holder is currently holding something
		if is_holding_item():
			
			# Player is holding a Plate
			if player.c_holder.get_held_item() is MultiHolder:
				var multi_h = player.c_holder.get_held_item() as MultiHolder
				# Put item onto Plate if space is available
				if multi_h.has_space_for_item(get_held_item()):
					release_item_to(multi_h)
				return
				
			swap_items_with(player.c_holder)
		# Holding nothing - Attempt to take from Player
		else:
			# Player holding Plate - This Holder doesn't accept Plates - Nothing on this Holder
			if not can_hold_holders and player.c_holder.get_held_item() is MultiHolder:
				var multi_h = player.c_holder.get_held_item() as MultiHolder
				# Take an item off the Player's Plate, put it onto this
				if multi_h.is_holding_item():
					multi_h.release_item_to(self)
				return
			
			# Take Player's item
			player.c_holder.release_item_to(self)
	# Player taking Item - Player not holding anything
	elif is_holding_item():
		release_item_to(player.c_holder)

# Right Clicking Holder
func _secondary_interact(player : Player):
	# Player trying to place Item
	if player.c_holder.is_holding_item():
		
		# Player trying to Right Click this Holder with just an Item
		if not player.c_holder.get_held_item() is MultiHolder:
			return
		
		# Player confirmed to have MultiHolder, likely Plate
		var multi_h : MultiHolder = player.c_holder.get_held_item()
		
		# This Holder has no space for the Plated item
		if not has_space_for_item(multi_h.get_held_item()):
			return
		
		# Player trying to place items from their Multi-holder onto our empty Holder
		if multi_h.is_holding_item():
			multi_h.release_item_to(self)
