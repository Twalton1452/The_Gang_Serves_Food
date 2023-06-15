extends Node3D
class_name Order

## Class to flatten the display items hierarchy to get an easier picture of the items
## Will allow for easy dissection of the state of each item

var order_score : float = 0.0 ## Customer's ideal score
var actual_score : float = 0.0 ## Dish given to them score

var display_order : Node3D = null
var multiholder_dish : bool = false
## Used for comparisons against food placed onto table
var flattened_order_ids : Array[NetworkedIds.Scene] = []

func set_sync_state(reader: ByteReader):
	# Kind of excessive because it should be a direct child
	var path_to_display_order = reader.read_path_to()
	var is_showing = reader.read_bool()
	if is_showing:
		show()
	
	# Wait for all the data below it to be populated
	await get_tree().physics_frame
	init(get_node(path_to_display_order))

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_path_to(display_order)
	var is_showing = visible
	writer.write_bool(is_showing)
	return writer

func init(display: Node3D):
	order_score = 0.0
	display_order = display
	hide()
	visual_representation()
	Utils.remove_all_interactable_children_from_interactable_collision_layer(self)
	
	multiholder_dish = display is MultiHolder
	flattened_order_ids = get_flattened_ids_for(display)
	order_score = get_score_for(display_order)

func get_score_for(dish: Node3D) -> float:
	var score = 0.0
	if dish is MultiHolder:
		for item in dish.get_held_items():
			if item is CombinedFoodHolder:
				for food in item.get_held_items():
					score += food.score * GameState.combined_food_multiplier
				
			elif item is Food or item is Drink:
				score += item.score
		score *= GameState.multiholder_multiplier
	else:
		if dish is CombinedFoodHolder:
			for food in dish.get_held_items():
				score += food.score * GameState.combined_food_multiplier
			
		elif dish is Food or dish is Drink:
			score += dish.score
	return score

func get_flattened_ids_for(dish: Node3D) -> Array[NetworkedIds.Scene]:
	var ids : Array[NetworkedIds.Scene] = []
	
	if dish is MultiHolder:
		ids.push_back(dish.SCENE_ID) # Requires the multiholder
		for item in dish.get_held_items():
			if item is CombinedFoodHolder:
				for food in item.get_held_items():
					ids.push_back(food.SCENE_ID)
				
			elif item is Food or item is Drink:
				ids.push_back(item.SCENE_ID)
	else:
		if dish is CombinedFoodHolder:
			for food in dish.get_held_items():
				ids.push_back(food.SCENE_ID)
			
		elif dish is Food or dish is Drink:
			ids.push_back(dish.SCENE_ID)
	
	return ids

func is_equal_to(presented_dish: Node3D) -> bool:
	if presented_dish is MultiHolder and not multiholder_dish:
		return false
	
	if multiholder_dish and not presented_dish is MultiHolder:
		return false
	
	var presented_dish_ids = get_flattened_ids_for(presented_dish)
	if presented_dish_ids.size() != flattened_order_ids.size():
		return false
	
	for i in len(presented_dish_ids):
		if presented_dish_ids[i] != flattened_order_ids[i]:
			return false
	
	actual_score = get_score_for(presented_dish)
	return true

func visual_representation():
	# Bounce up and down
	# Not sync'd with server, but its an inconsequential visual
	var floater = Floater.new()
	floater.move_enabled = true
	floater.move_amount = Vector3(0.0, 0.05, 0.0)
	floater.move_to_original_seconds = 1.3
	floater.move_to_target_seconds = 1.3
	floater.move_transition_to_target = Tween.TRANS_BACK
	floater.move_transition_to_target = Tween.TRANS_BACK
	display_order.add_child(floater)
	
	if display_order is MultiHolder:
		for item in display_order.get_held_items():
			if item is CombinedFoodHolder:
				for food in item.get_held_items():
					set_transparency_for_food_to(food, 0.7)
			elif item is Food:
				set_transparency_for_food_to(item, 0.7)
			elif item is Drink:
				set_transparency_for_drink_to(item, 0.7)
	else:
		if display_order is CombinedFoodHolder:
			for food in display_order.get_held_items():
				set_transparency_for_food_to(food, 0.7)
			
		elif display_order is Food:
			set_transparency_for_food_to(display_order, 0.7)
		elif display_order is Drink:
			set_transparency_for_drink_to(display_order, 0.7)

func set_transparency_for_food_to(food: Food, value: float):
	for i in range(food.obj_to_color.get_surface_override_material_count()):
		var material = food.obj_to_color.get_active_material(i)
		if material != null:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = value

func set_transparency_for_drink_to(drink: Drink, value: float):
	for i in range(drink.mesh_to_color.get_surface_override_material_count()):
		var material = drink.mesh_to_color.get_active_material(i)
		if material != null:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = value
