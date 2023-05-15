extends Node3D
class_name HolderComponent

signal started_holding(node: Node3D)
signal released_holding(node: Node3D)

var c_interactable : InteractableComponent

const SCENE_ID = SceneIds.SCENES.HOLDER
var net_id = -1

func _ready():
	net_id = NetworkingUtils.generate_id()
	
	add_to_group(str(SCENE_ID))
	
	connect_signals.call_deferred()

func _notification(what):
	if what == NOTIFICATION_MOVED_IN_PARENT:
		print("%s unparented" % name)

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

func has_space_for_item():
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
	#print("HOLDING %s" % item.net_id)
	if not item.is_inside_tree():
		add_child(item, true)
	elif not is_holding(item):
		item.reparent(self, false)
	started_holding.emit(item)
	item.position = Vector3.ZERO

func release_item_to(holder: HolderComponent):
	var item = get_held_item()
	released_holding.emit(item)
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
				release_item_to(player.c_holder.get_held_item())
				return
			
			swap_items_with(player.c_holder)
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
		if not has_space_for_item():
			return
		
		# Player trying to place items from their Multi-holder onto our empty Holder
		player.c_holder.get_held_item().release_item_to(self)
