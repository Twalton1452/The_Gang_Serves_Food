extends Interactable
class_name Holder

signal holding_item(item: Node3D)
signal released_item(item: Node3D)

var is_static_holder = false

func _ready():
	super()
	is_static_holder = not get_parent() is Holder

func can_hold_this(item: Node3D) -> bool:
	return item is Holdable or item is Holder

func get_held_items() -> Array[Node]:
	if get_child_count() > 0:
		return get_children().filter(func(item): return item is Holdable or item is Holder)
	return []

func has_space_for_item(_item: Node3D) -> bool:
	return len(get_held_items()) == 0

func is_holding_item() -> bool:
	return len(get_held_items()) > 0

func get_held_item() -> Node3D:
	if is_holding_item():
		return get_held_items()[-1]
	return null

func is_holding(item: Node3D) -> bool:
	if not is_holding_item():
		return false
	for child in get_children():
		if child == item:
			return true
	return false

func is_acceptable(item: Node3D) -> bool:
	# Separated these if statements out for easy readability and extensibility, can condense later
	if item == null and not has_space_for_item(item):
		return false
	# Don't allow Plate's or Food Containers on anything but static geometry
	if (item is StackingHolder or item is MultiHolder) and not is_static_holder and not item is CombinedFoodHolder:
		return false
	return true

func hold_item(item: Node3D) -> void:
	if not is_acceptable(item):
		return
	
	hold_item_unsafe(item)

func hold_item_unsafe(item: Node3D) -> void:
	if not item.is_inside_tree():
		add_child(item, true)
	elif not is_holding(item):
		item.reparent(self, false)
	item.position = Vector3.ZERO
	holding_item.emit(item)

func release_item_to(holder: Holder):
	release_this_item_to(get_held_item(), holder)
	
func release_this_item_to(item: Node3D, holder: Holder):
	holder.hold_item(item)
	released_item.emit(item)
	
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
	if player.holder.is_holding_item():
		# This Holder is currently holding something
		if is_holding_item():
			
			# Player is holding a Plate
			if player.holder.get_held_item() is MultiHolder:
				var multi_h : MultiHolder = player.holder.get_held_item()
				# Put item onto Plate if space is available
				if multi_h.has_space_for_item(get_held_item()):
					release_item_to(multi_h)
				return
			
			if player.holder.get_held_item() is StackingHolder and not player.holder.get_held_item() is CombinedFoodHolder:
				var stacking_h : StackingHolder = player.holder.get_held_item()
				if stacking_h.acceptable_item(get_held_item()):
					release_item_to(stacking_h)
				return
				
			swap_items_with(player.holder)
		# Holding nothing - Attempt to take from Player
		else:			
			# Take Player's item
			player.holder.release_item_to(self)
	# Player taking Item - Player not holding anything
	elif is_holding_item():
		release_item_to(player.holder)
	# Neither player nor this Holder has an item, likely an empty MultiHolder like a Plate
	elif get_parent() is Holder:
		(get_parent() as Holder).interact(player)

# Right Clicking Holder
func _secondary_interact(player : Player):
	# Player trying to place Item
	if player.holder.is_holding_item():
		
		# Player trying to Right Click this Holder with just an Item
		if not player.holder.get_held_item() is MultiHolder:
			# Player probably just wants to put the item down
			# if they are right clicking an empty holder with an item
			if not is_holding_item():
				_interact(player)
			return
		
		# Player confirmed to have MultiHolder, likely Plate
		var multi_h : MultiHolder = player.holder.get_held_item()
		
		# This Holder has no space for the Plated item
		if not has_space_for_item(multi_h.get_held_item()):
			return
		
		# Player trying to place items from their Multi-holder onto our empty Holder
		if multi_h.is_holding_item():
			multi_h.release_item_to(self)
