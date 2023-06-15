extends Holder
class_name MultiHolder

@export var is_pickupable = true

var holders : Array[Holder] = []

func set_sync_state(reader: ByteReader) -> void:
	for holder in holders:
		holder.set_sync_state(reader)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	for holder in holders:
		holder.get_sync_state(writer)
	
	return writer

func _ready():
	super()
	for child in get_children():
		if child is Holder:
			holders.push_back(child)
	
	# Enable the fallback colliders based on if there are items or not
	if len(get_held_items()) > 0:
		disable_colliders()
	else:
		enable_colliders()
	

func get_held_items() -> Array[Node]:
	var items : Array[Node] = []
	
	for holder in holders:
		if holder is StackingHolder or holder is MultiHolder:
			items.append_array(holder.get_held_items())
		elif holder.is_holding_item():
			items.push_back(holder.get_held_item())
	return items

func has_space_for_item(_item: Node3D) -> bool:
	return len(get_held_items()) < len(holders)

func get_held_item() -> Node3D:
	if is_holding_item():
		return get_held_items()[-1]
	return null

func is_holding(item: Node3D):
	if not is_holding_item():
		return false
	for holder in holders:
		if holder.get_held_item() == item:
			return true

func hold_item(item: Node3D) -> void:
	for holder in holders:
		if not holder.is_holding_item() and holder.is_enabled():
			holder.hold_item(item)
			break

func _interact(player: Player):
	# Let the Holder take care of the interaction
	if is_pickupable:
		if get_parent() is Holder:
			(get_parent() as Holder).interact(player)
		elif not player.holder.is_holding_item():
			player.holder.hold_item(self)
	else:
		super(player)

func disable_colliders():
	for holder in holders:
		holder.disable_collider()

func enable_colliders():
	for holder in holders:
		holder.enable_collider()
