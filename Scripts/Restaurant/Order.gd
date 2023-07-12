extends Node3D
class_name Order

## Class to flatten the display items hierarchy to get an easier picture of the items
## Will allow for easy dissection of the state of each item

var order_score : float = 0.0 ## Customer's ideal score
var actual_score : float = 0.0 ## Dish given to them score

var display_order : Node3D = null
var multiholder_dish : bool = false
## Used for comparisons against food placed onto table
var scene_flattened_ids : Array[NetworkedIds.Scene] = []
var resource_flattened_ids : Array[NetworkedIds.Resources] = []

var order_visual_mat = preload("res://Materials/Order_Visual_mat.tres")

## Customer desires for variations
## positive means they want that as extra, negative value means to take one of those away
#var wanted_flattened_ids : Array[int] = []

static func get_score_for(dish: Node3D) -> float:
	var score = 0.0
	if dish is MultiHolder:
		for item in dish.get_held_items():
			if item is CombinedFoodHolder:
				for food in item.get_held_items():
					score += food.score * GameState.combined_food_multiplier
				
			elif item is Food:
				score += item.score
			elif item is Drink:
				score += item.score
		score *= GameState.multiholder_multiplier
	else:
		if dish is CombinedFoodHolder:
			for food in dish.get_held_items():
				score += food.score * GameState.combined_food_multiplier
			
		elif dish is Food or dish is Drink:
			score += dish.score
	return score

func set_sync_state(reader: ByteReader):
	# Kind of excessive because it should be a direct child
	var path_to_display_order = reader.read_path_to()
	var is_showing = reader.read_bool()
	
	# Wait for all the data below it to be populated
	await get_tree().physics_frame
	init(get_node(path_to_display_order))
	if is_showing:
		show()

func get_sync_state(writer: ByteWriter) -> void:
	writer.write_path_to(display_order)
	var is_showing = visible
	writer.write_bool(is_showing)

func init(display: Node3D):
	display_order = display
	hide()
	visual_representation()
	Utils.remove_from_interactable_layer(self)
	
	multiholder_dish = display is MultiHolder
	var ids = get_flattened_ids_for(display)
	scene_flattened_ids = ids[0]
	resource_flattened_ids = ids[1]
	order_score = Order.get_score_for(display_order)

## Returns 2 arrays in one Array[Array[NetworkedIds.Scene], Array[NetworkedIds.Resources]]
## Godot doesn't support nested typed Arrays, so we just have to go generic
func get_flattened_ids_for(dish: Node3D) -> Array:
	var ids : Array[NetworkedIds.Scene] = []
	var resource_ids : Array[NetworkedIds.Resources] = []
	if dish is MultiHolder:
		ids.push_back(dish.SCENE_ID) # Requires the multiholder
		for item in dish.get_held_items():
			if item is CombinedFoodHolder:
				for food in item.get_held_items():
					ids.push_back(food.SCENE_ID)
				
			elif item is Food:
				ids.push_back(item.SCENE_ID)
			elif item is Drink:
				ids.push_back(item.SCENE_ID)
				for beverage in item.beverage_amounts:
					resource_ids.push_back(beverage.RESOURCE_ID)
	else:
		if dish is CombinedFoodHolder:
			for food in dish.get_held_items():
				ids.push_back(food.SCENE_ID)
			
		elif dish is Food:
			ids.push_back(dish.SCENE_ID)
		elif dish is Drink:
			ids.push_back(dish.SCENE_ID)
			for beverage in dish.beverage_amounts:
					resource_ids.push_back(beverage.RESOURCE_ID)
	
	return [ids, resource_ids]

func is_equal_to(presented_dish: Node3D) -> bool:
	if presented_dish is MultiHolder and not multiholder_dish:
		return false
	
	if multiholder_dish and not presented_dish is MultiHolder:
		return false
	
	var ids = get_flattened_ids_for(presented_dish)
	var presented_dish_order_ids = ids[0]
	var presented_dish_resource_ids = ids[1]
	
	if presented_dish_order_ids.size() != scene_flattened_ids.size():
		return false
	if presented_dish_resource_ids.size() != resource_flattened_ids.size():
		return false
	
	for i in len(presented_dish_order_ids):
		if presented_dish_order_ids[i] != scene_flattened_ids[i]:
			return false
	
	for i in len(presented_dish_resource_ids):
		if presented_dish_resource_ids[i] != resource_flattened_ids[i]:
			return false
	
	actual_score = Order.get_score_for(presented_dish)
	return true

func visual_representation():
	# Bounce up and down - not sync'd with server
	var floater = Floater.new()
	floater.move_enabled = true
	floater.move_amount = Vector3(0.0, 0.05, 0.0)
	floater.move_to_original_seconds = 1.3
	floater.move_to_target_seconds = 1.3
	floater.move_transition_to_target = Tween.TRANS_BACK
	floater.move_transition_to_target = Tween.TRANS_BACK
	display_order.add_child(floater)
	
#	if display_order is MultiHolder:
#		for item in display_order.get_held_items():
#			if item is CombinedFoodHolder:
##				item.scale.z = 0.1
#				for food in item.get_held_items():
#					#set_transparency_for_food_to(food, 0.7)
#					set_material_overlay_for_food(food)
#			elif item is Food:
#				set_material_overlay_for_food(item)
##				item.scale.z = 0.1
#				#set_transparency_for_food_to(item, 0.7)
#			elif item is Drink:
#				set_material_overlay_for_drink(item)
##				item.scale.y = 0.5
#				#set_transparency_for_drink_to(item, 0.7)
#	else:
#		if display_order is CombinedFoodHolder:
##			display_order.scale.z = 0.1
#			for food in display_order.get_held_items():
#				set_material_overlay_for_food(food)
#				#set_transparency_for_food_to(food, 0.7)
#
#		elif display_order is Food:
#			set_material_overlay_for_food(display_order)
##			display_order.scale.z = 0.1
#			#set_transparency_for_food_to(display_order, 0.7)
#		elif display_order is Drink:
#			set_material_overlay_for_drink(display_order)
##			display_order.scale.y = 0.5
#			#set_transparency_for_drink_to(display_order, 0.7)

func set_material_overlay_for_food(food: Food):
	food.obj_to_color.material_overlay = order_visual_mat

func set_material_overlay_for_drink(drink: Drink):
	drink.mesh_to_color.material_overlay = order_visual_mat

func set_transparency_for_food_to(food: Food, value: float):
	for i in range(food.obj_to_color.get_surface_override_material_count()):
		var material = food.obj_to_color.get_surface_override_material(i)
		if material != null:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = value

func set_transparency_for_drink_to(drink: Drink, value: float):
	for i in range(drink.mesh_to_color.get_surface_override_material_count()):
		var material = drink.mesh_to_color.get_surface_override_material(i)
		if material != null:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = value
