extends Node3D
class_name MenuItem

signal changed

@export var dish_display_holder : Holder

#var dish_holder : NetworkedIds.Scene = null
var dish : Array[NetworkedIds.Scene] = []

func _ready():
	dish_display_holder.interacted.connect(_on_holder_changed)
	dish_display_holder.secondary_interacted.connect(_on_holder_changed)
	_on_holder_changed()

func _on_holder_changed():
	dish = extract_scene_ids_from(dish_display_holder)
	changed.emit()

## TODO: revisit if necessary
func extract_scene_ids_from(holder: Holder) -> Array[NetworkedIds.Scene]:
	var ids : Array[NetworkedIds.Scene] = []
	if not holder.is_holding_item():
		return ids
	
	var held_item = holder.get_held_item()
	
	if held_item is MultiHolder:
		ids.push_back(held_item.SCENE_ID)
		for item in held_item.get_held_items():
			if item is CombinedFoodHolder:
				for food in item.get_held_items():
					ids.push_back((food as Food).SCENE_ID)
			elif item is Drink or item is Food:
				ids.push_back(item.SCENE_ID)
				
		
		return ids
	
	if held_item is CombinedFoodHolder:
		for item in held_item.get_held_items():
			ids.push_back((item as Food).SCENE_ID)
	
	return ids

func get_dish() -> Array[NetworkedIds.Scene]:
	return dish

func is_dish_available() -> bool:
	return not dish.is_empty()
