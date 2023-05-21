extends Holder
class_name MultiHolder

@export var is_pickupable = false

var c_holders : Array[Holder]

func _ready():
	#super()
	
	for child in get_children():
		if child is Holder:
			c_holders.push_back(child)
	
	assert(len(c_holders) > 0, "MultiHolder: %s, Parent: %s, doesn't have any holders" \
		% [name, get_parent().name])
	

func get_held_items() -> Array[Node]:
	var items : Array[Node] = []
	
	for c_holder in c_holders:
		if c_holder is StackingHolder or c_holder is MultiHolder:
			items.append_array(c_holder.get_held_items())
		elif c_holder.is_holding_item():
			items.push_back(c_holder.get_held_item())
	return items

func has_space_for_item(_item: Node3D) -> bool:
	return len(get_held_items()) < len(c_holders)

func get_held_item() -> Node3D:
	if is_holding_item():
		return get_held_items()[-1]
	return null

func is_holding(item: Node3D):
	if not is_holding_item():
		return false
	for holder in c_holders:
		if holder.get_held_item() == item:
			return true

func hold_item(item: Node3D) -> void:
	for holder in c_holders:
		if not holder.is_holding_item():
			holder.hold_item(item)
			break

func _interact(player: Player):
	# Let the Holder take care of the interaction
	if is_pickupable:
		(get_parent() as Holder).interact(player)
	else:
		super(player)
	
