extends Node
class_name HolderComponent

signal started_holding(node: Node3D)
signal released_holding(node: Node3D)

var connector : InteractableComponent

const SCENE_ID = SceneIds.SCENES.HOLDER
var net_id = -1

func _ready():
	net_id = NetworkingUtils.generate_id()
	
	add_to_group(str(SCENE_ID))
	
	connect_signals.call_deferred()

func connect_signals():
	# Look up and down for an InteractableComponent
	connector = get_node("../InteractableComponent") if get_node_or_null("../InteractableComponent") != null else get_node_or_null("InteractableComponent")
	# This is likely to be a Player's hand, they don't have hitboxes around them
	if connector == null:
		return
	
	connector.interacted.connect(_on_interactable_component_interacted)

func get_held_items() -> Array[Node]:
	if get_child_count() > 0:
		return get_children().filter(func(c): return c is HoldableComponent)
	return []

func is_holding_item() -> bool:
	return len(get_held_items()) > 0

func get_held_item() -> Node3D:
	if is_holding_item():
		return get_child(-1)
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

func _on_interactable_component_interacted(_node : InteractableComponent, player : Player):
	# Player placing Item
	if player.holder_component.is_holding_item():
		# Swap Items - This Holder is currently holding something
		if is_holding_item():
			var curr_item = get_held_item()
			released_holding.emit(curr_item)
			
			# TODO:
			# If player right clicked to interact
			# Attempt to combine the curr_item onto the Holder
			hold_item(player.holder_component.get_held_item())
			player.holder_component.hold_item(curr_item)
			
		# Take Player's item
		else:
			hold_item(player.holder_component.get_held_item())
	# Player taking Item - Player not holding anything
	elif is_holding_item():
		released_holding.emit(get_held_item())
		player.holder_component.hold_item(get_held_item())
		
