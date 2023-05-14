extends NetworkedNode3D
class_name HoldableComponent

@onready var c_interactable = $InteractableComponent

func set_sync_state(value) -> int:
	var continuing_offset = super(value)
	var is_being_held = bool(value.decode_u8(continuing_offset))
	if is_being_held:
		(get_parent() as HolderComponent).hold_item(self)
	
	return continuing_offset + 1

func get_sync_state() -> PackedByteArray:
	var buf = super()
	var end_of_parent_buf = buf.size()
	var is_being_held = get_parent() is HolderComponent
	buf.resize(end_of_parent_buf + 1)
	buf.encode_u8(end_of_parent_buf, is_being_held) # u8 is 1 byte
	return buf

func _ready():
	super()
	connect_signals.call_deferred()

func connect_signals():
	c_interactable.interacted.connect(_on_interactable_component_interacted)
	c_interactable.secondary_interacted.connect(_on_interactable_component_secondary_interacted)

# This probably needs a rewrite, just emit signals that you're being held and let the Holder's take care of it
# Holdable's are doing too much and really shouldn't be
# Left Click
func _on_interactable_component_interacted(_node : InteractableComponent, player : Player):
	# Player is currently holding something
	if player.holder_component.is_holding_item():
		# Player is holding a Plate, put this onto it if available
		if player.holder_component.get_held_item() is HoldableComponent:
			for holdable_child in player.holder_component.get_held_item().get_children():
				# Found a Holder and there is an available slot
				if holdable_child is HolderComponent and not holdable_child.is_holding_item():
					holdable_child.hold_item(self)
					return
		# Couldn't find an available slot if the Player was holding a Plate
		# Swap Items
		# Assumption is every Holdable belongs to a Holder right now
		if get_parent() is HolderComponent:
			get_parent().hold_item(player.holder_component.get_held_item())
		player.holder_component.hold_item(self)
	# Player taking Item - Player not holding anything
	else:
		if get_parent() is HolderComponent:
			(get_parent() as HolderComponent).notify_release(self)
		player.holder_component.hold_item(self)

# Right Click
func _on_interactable_component_secondary_interacted(_node : InteractableComponent, player : Player):
	# Combine
	if player.holder_component.is_holding_item():
		pass
		
		#player.holder_component.get_held_item().stack_item(self)
		

# ---------------------------NOTICE--------------------------------------- #
# STEALING FROM HolderComponent.gd UNTIL I FIGURE OUT A BETTER WAY FOR NOW #
# JUST MAKE IT WORK, REFACTOR LATER                                        #
# ------------------------------------------------------------------------ #
func is_holding_item() -> bool:
	return get_child_count() > 0

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
	item.position = Vector3.ZERO

# STOLEN FROM IngredientComponent.gd
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)
var max_amount = 99

# TODO:
# Holders and Holdables are competiting to whichever hitbox is interacted with first
# Need to consolidate before moving on
func stack_item(item: Node3D):
	if is_holding(item):
		return
	
	var holdables = get_children().filter(func(c): return c is HoldableComponent)
	
	if holdables.size() < max_amount:
		if item.get_parent() is HolderComponent:
			item.get_parent().notify_release(item)
		hold_item(item)
		if holdables.size() > 1:
			item.position = holdables[-2].position + stacking_spacing
			print(item.position)
		else:
			item.position = stacking_spacing
