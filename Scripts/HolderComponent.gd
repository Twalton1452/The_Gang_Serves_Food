extends Node
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
		return get_children().filter(func(c): return c is HoldableComponent)
	return []

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

func notify_release(item: Node3D):
	released_holding.emit(item)

# Left Clicking Holder
func _on_interactable_component_interacted(_node : InteractableComponent, player : Player):
	# Player placing Item
	if player.holder_component.is_holding_item():
		# Swap Items - This Holder is currently holding something
		if is_holding_item():
			var curr_item = get_held_item()
			released_holding.emit(curr_item)
			
			# Player is holding a Plate, put this onto it if available
			if player.holder_component.get_held_item() is HoldableComponent:
				for holdable_child in player.holder_component.get_held_item().get_children():
					# Found a Holder and there is an available slot
					if holdable_child is HolderComponent and not holdable_child.is_holding_item():
						holdable_child.hold_item(get_held_item())
						return
			
			# TODO:
			# If player right clicked to interact
			# Attempt to combine the curr_item onto the Holder
			hold_item(player.holder_component.get_held_item())
			player.holder_component.hold_item(curr_item)
			
		# Take Player's item
		else:
			player.holder_component.notify_release(player.holder_component.get_held_item())
			hold_item(player.holder_component.get_held_item())
	# Player taking Item - Player not holding anything
	elif is_holding_item():
		released_holding.emit(get_held_item())
		player.holder_component.hold_item(get_held_item())

# Right Clicking Holder
func _on_interactable_component_secondary_interacted(_node : InteractableComponent, player : Player):
	# Player trying to place Item
	if player.holder_component.is_holding_item():
		
		var multi_holder = player.holder_component.get_held_item() is HoldableComponent and \
			len(player.holder_component.get_held_item().get_children().filter(func(child): return child is HolderComponent)) > 0
		
		if not multi_holder:
			# Combine?
			return
		
		if is_holding_item():
			# Player trying to put items from their Plate onto this occupied Holder
			return
		
		var occupied_holders = player.holder_component.get_held_item().get_children().filter(func(child): return child is HolderComponent and child.is_holding_item())
		for holder in occupied_holders:
			# Found a Holder and there is an available slot
			holder.notify_release(holder.get_held_item())
			hold_item(holder.get_held_item())
			return
