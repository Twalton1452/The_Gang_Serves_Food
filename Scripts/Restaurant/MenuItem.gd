extends Node3D
class_name MenuItem

signal changed

@export var dish_holder : Holder

var dish : Array[SceneIds.SCENES] = []

func _ready():
	dish_holder.interacted.connect(_on_holder_changed)
	_on_holder_changed()

func _on_holder_changed():
	dish = extract_scene_ids_from(dish_holder)
	changed.emit()

func extract_scene_ids_from(holder: Holder) -> Array[SceneIds.SCENES]:
	var ids : Array[SceneIds.SCENES] = []
	if not holder.is_holding_item():
		return ids
	
	if holder.get_held_item() is CombinedFoodHolder:
		for item in holder.get_held_item().get_held_items():
			ids.push_back((item as Food).SCENE_ID)
	
	return ids

func get_dish() -> Array[SceneIds.SCENES]:
	return dish
