extends HolderComponent
class_name MultiHolderComponent

var c_holders : Array[HolderComponent]

func _ready():
	super()
	
	for child in get_children():
		if child is HolderComponent:
			c_holders.push_back(child)
	
	assert(len(c_holders) > 0, "MultiHolderComponent: %s, Parent: %s, doesn't have any holders" \
		% [name, get_parent().name])

func get_held_items() -> Array[Node]:
	var items : Array[Node] = []
	
	for c_holder in c_holders:
		if c_holder.is_holding_item():
			items.push_back(c_holder.get_held_item())
		
	return items

func has_space_for_item():
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

func hold_item(item: Node3D):
	#print("HOLDING %s" % item.net_id)
	for holder in c_holders:
		if holder.is_holding_item():
			continue
		holder.hold_item(item)
#	started_holding.emit(item)
