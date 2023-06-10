extends Node3D
class_name Order

## Class to flatten the display items hierarchy to get an easier picture of the items
## Will allow for easy dissection of the state of each item

var display_order : Node3D = null
var multiholder : MultiHolder = null
var combined_foods : Array[CombinedFoodHolder] = []
var foods : Array[Food] = []
var drinks : Array[Drink] = []

## Used for comparisons against food placed onto table
var flattened_order_ids : Array[NetworkedIds.Scene] = []

func set_sync_state(reader: ByteReader):
	(get_parent() as Customer).order = self
	
	await MidsessionJoinSyncer.sync_complete # Wait for children to be created
	
	# Kind of excessive because it should be a direct child
	var path_to_display_order = reader.read_path_to()
	init(get_node(path_to_display_order))
	print(path_to_display_order, " ", get_children())
	for child in get_children():
		print(child.get_children())
	print("-------------------------------------")
	var is_showing = reader.read_bool()
	if is_showing:
		show()
	
	# Don't really like this here, but the Order needs to wait for the children to spawn
	# Before the Customer above can evaluate what is on the table
	# I think the solution here is to just have state on the customer
	# Alternatively each Food could set its own collider state
	(get_parent() as Customer).evaluate_food()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_path_to(display_order)
	var is_showing = visible
	writer.write_bool(is_showing)
	return writer

func init(display: Node3D):
	hide()
	display_order = display
	flattened_order_ids = get_flattened_ids_for(display)
	
	if display is MultiHolder:
		multiholder = display
	
	if multiholder != null:
		for item in multiholder.get_held_items():
			
			if item is CombinedFoodHolder:
				combined_foods.push_back(item)
				item.disable_held_colliders()
			
			elif item is Food:
				foods.push_back(item)
				item.disable_collider()
			
			elif item is Drink:
				drinks.push_back(item)
				item.disable_collider()
	else:
		if display is CombinedFoodHolder:
			combined_foods.push_back(display)
			display.disable_held_colliders()
		
		elif display is Food:
			foods.push_back(display)
			display.disable_collider()
		
		elif display is Drink:
			drinks.push_back(display)
			display.disable_collider()
	
	visual_representation()

func get_flattened_ids_for(dish: Node3D) -> Array[NetworkedIds.Scene]:
	var ids : Array[NetworkedIds.Scene] = []
	
	if dish is MultiHolder:
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
	if presented_dish is MultiHolder and multiholder == null:
		return false
		
	var presented_dish_ids = get_flattened_ids_for(presented_dish)	
	if presented_dish_ids.size() != flattened_order_ids.size():
		return false
	
	for i in len(presented_dish_ids):
		if presented_dish_ids[i] != flattened_order_ids[i]:
			return false
	
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
	
	#display_order.add_child(floater)
	#display_order.scale.z = 0.1
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
		food.obj_to_color.get_active_material(i)
		food.material_to_color.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		food.material_to_color.albedo_color.a = value

func set_transparency_for_drink_to(drink: Drink, value: float):
	for i in range(drink.mesh_to_color.get_surface_override_material_count()):
		drink.obj_to_color.get_active_material(i)
		drink.material_to_color.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		drink.material_to_color.albedo_color.a = value
