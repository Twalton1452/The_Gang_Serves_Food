extends NetworkedNode3D
class_name HoldableComponent

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
	connect_signals.call_deferred()

func connect_signals():
	var connector = get_node_or_null("InteractableComponent")
	assert(connector != null, "%s is not interactable, add InteractableComponent to this" % name)
	
	connector.interacted.connect(_on_interactable_component_interacted)

func _on_interactable_component_interacted(_node : InteractableComponent, player : Player):
	# Swapping Items - Player is currently holding something
	if player.holder_component.is_holding_item():
		# TODO:
		# If player right clicked to interact
		# Attempt to combine the curr_item onto the Holder
		
		# Assumption is every Holdable belongs to a Holder right now
		if get_parent() is HolderComponent:
			get_parent().hold_item(player.holder_component.get_held_item())
		player.holder_component.hold_item(self)
	# Player taking Item - Player not holding anything
	else:
		if get_parent() is HolderComponent:
			(get_parent() as HolderComponent).notify_release(self)
		player.holder_component.hold_item(self)
