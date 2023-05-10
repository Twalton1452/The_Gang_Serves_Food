extends Node
class_name HolderComponent

## The highest parent in the scene for renaming/syncing purposes
@export var true_parent : Node3D

const SCENE_ID = SceneIds.SCENES.HOLDER

func _ready():
	assert(true_parent != null, \
		"Assign a true_parent to this HolderComponent so we can stay sync'd correctly")
	name = name + "_" + true_parent.name
		
	add_to_group(str(SCENE_ID))

func joined_midsession_sync(item_to_hold: Node3D):
	hold_item(item_to_hold)

func is_holding_item() -> bool:
	return get_child_count() > 0

func get_held_item() -> Node3D:
	return get_child(-1)

func hold_item(item: Node3D):
	if not item.is_inside_tree():
		add_child(item, true)
	else:
		item.reparent(self, false)
	item.position = Vector3.ZERO
