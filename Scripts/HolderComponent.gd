extends NetworkedNode3D
class_name HolderComponent

signal started_holding(node: Node3D)
#signal released_holding(node: Node3D)

@export var can_hold_holders = true

var c_interactable : InteractableComponent

func _ready():
	super()
	connect_signals.call_deferred()

func connect_signals():
	# Look up and down for an InteractableComponent
	c_interactable = get_node("InteractableComponent") if get_node_or_null("InteractableComponent") != null else get_node_or_null("../InteractableComponent")
	# This is likely to be a Player's hand, they don't have hitboxes around them
	if c_interactable == null:
		return
	
	c_interactable.interacted.connect(_on_interactable_component_interacted)
	c_interactable.secondary_interacted.connect(_on_interactable_component_secondary_interacted)

func get_held_items() -> Array[Node]:
	if get_child_count() > 0:
		return get_children().filter(func(c): return c is HoldableComponent or c is HolderComponent)
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

func hold_item(item: Node3D):
	if item is HolderComponent and not can_hold_holders:
		return
	
	#print("HOLDING %s" % item.net_id)
	if not item.is_inside_tree():
		add_child(item, true)
	elif not is_holding(item):
		item.reparent(self, false)
	started_holding.emit(item)
	item.position = Vector3.ZERO

func release_item_to(holder: HolderComponent):	
	var item = get_held_item()
	#released_holding.emit(item)
	holder.hold_item(item)
	
func swap_items_with(holder: HolderComponent):
	var curr_item = get_held_item()
	holder.release_item_to(self)
	holder.hold_item(curr_item)

# Left Clicking Holder
func _on_interactable_component_interacted(_node : InteractableComponent, player : Player):
	# Player placing Item
	if player.c_holder.is_holding_item():
		# Swap Items - This Holder is currently holding something
		if is_holding_item():
			
			# Player is holding a Plate, put this onto it if available
			if player.c_holder.get_held_item() is MultiHolderComponent:
				# Place the whole Plate here
				if can_hold_holders:
					release_item_to(player.c_holder.get_held_item())
				# Give this Holder's item to Player's Holder
				elif player.c_holder.get_held_item().has_space_for_item(get_held_item()):
					release_item_to(player.c_holder.get_held_item())
				return
			
			swap_items_with(player.c_holder)
		# Holding nothing - Attempt to take from Player
		else:
			# Player holding Plate
			if not can_hold_holders and player.c_holder.get_held_item() is MultiHolderComponent:
				# Take an item off the Player's Plate, put it onto this
				if player.c_holder.get_held_item().is_holding_item():
					player.c_holder.get_held_item().release_item_to(self)
			# Take Player's item
			else:
				player.c_holder.release_item_to(self)
	# Player taking Item - Player not holding anything
	elif is_holding_item():
		release_item_to(player.c_holder)

# Right Clicking Holder
func _on_interactable_component_secondary_interacted(_node : InteractableComponent, player : Player):
	# Player trying to place Item
	if player.c_holder.is_holding_item():
		
		# Player trying to Right Click this Holder with just an Item
		if not player.c_holder.get_held_item() is MultiHolderComponent:
			# Combine?
			return
		
		# Holder has no space - Combining didn't take place
		if not has_space_for_item(player.c_holder.get_held_item().get_held_item()):
			return
		
		# Player trying to place items from their Multi-holder onto our empty Holder
		if player.c_holder.get_held_item().is_holding_item():
			player.c_holder.get_held_item().release_item_to(self)
