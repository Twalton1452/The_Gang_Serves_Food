extends Holder
class_name EditModeHolder

func is_acceptable(item: Node3D) -> bool:
	# Separated these if statements out for easy readability and extensibility, can condense later
	if item == null and not has_space_for_item(item):
		return false
	return true

func disable_colliders_for(node: Node3D) -> void:
	pass

func hold_item_unsafe(item: Node3D) -> void:
	super(item)
	disable_colliders_for(item)
	
