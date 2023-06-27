extends Node3D
class_name MenuItem

signal changed

@export var dish_display_holder : Holder

@onready var score_label = $ScoreLabel
var SCORE_FORMAT = "$%1.2f"
#var dish_holder : NetworkedIds.Scene = null
var dish : Array[NetworkedIds.Scene] = []
var score : float = 0.0 : set = set_score

func set_score(value: float) -> void:
	score = value
	score_label.text = SCORE_FORMAT % value

func _ready():
	dish_display_holder.holding_item.connect(_on_holding_item)
	dish_display_holder.released_item.connect(_on_released_item)
	if dish_display_holder.is_holding_item():
		_on_holding_item(dish_display_holder.get_held_item())

func _on_holding_item(item: Node3D):
	dish = extract_scene_ids_from(item)
	if dish.size() > 0:
		score = Order.get_score_for(item)
	else:
		score = 0.0
	changed.emit()

func _on_released_item(_item: Node3D):
	dish = []
	score = 0.0
	changed.emit()

func extract_scene_ids_from(item: Node3D) -> Array[NetworkedIds.Scene]:
	var ids : Array[NetworkedIds.Scene] = []
	if item == null:
		score = 0.0
		return ids
	
	if item is MultiHolder:
		ids.push_back(item.SCENE_ID)
		for held_item in item.get_held_items():
			if held_item is CombinedFoodHolder:
				for food in held_item.get_held_items():
					ids.push_back((food as Food).SCENE_ID)
				
			elif held_item is Holdable:
				ids.push_back(held_item.SCENE_ID)
				
		# If its just the multiholder, there is no menu item
		if ids.size() == 1:
			return []
		return ids
	
	if item is CombinedFoodHolder:
		for held_item in item.get_held_items():
			ids.push_back((held_item as Food).SCENE_ID)
		return ids
	
	if item is Food or item is Drink:
		ids.push_back(item.SCENE_ID)
		return ids
	
	
	return ids

func get_dish() -> Array[NetworkedIds.Scene]:
	return dish

func is_dish_available() -> bool:
	return not dish.is_empty()
