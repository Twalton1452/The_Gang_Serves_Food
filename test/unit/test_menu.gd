extends TestingUtils

var _menu : Menu
var _menu_item : MenuItem

func before_each():
	var holder = Holder.new()
	add_child_autoqfree(holder)
	
	_menu_item = MenuItem.new()
	var score_label = Label3D.new()
	score_label.name = "ScoreLabel"
	_menu_item.add_child(score_label)
	_menu_item.dish_display_holder = holder
	
	var orders_parent = Node3D.new()
	_menu = Menu.new()
	_menu.orders_parent = orders_parent
	_menu.add_child(_menu_item)
	add_child_autoqfree(orders_parent)
	add_child_autoqfree(_menu)

func test_extracts_scene_ids_from_combined_food():
	# Arrange
	var ev : Array[NetworkedIds.Scene] = [NetworkedIds.Scene.BOTTOM_BUN, NetworkedIds.Scene.PATTY, NetworkedIds.Scene.TOMATO, NetworkedIds.Scene.TOP_BUN]
	var combined_food_holder = create_combined_food(ev)
	
	_menu_item.dish_display_holder.hold_item(combined_food_holder)
	
	# Act
	var main = _menu.menu_items[0].dish
	
	# Assert
	assert_eq(main, ev, "menu dish had something different")

func test_extracts_scene_ids_from_multi_holder():
	# Arrange
	var combined_food : Array[NetworkedIds.Scene] = [NetworkedIds.Scene.BOTTOM_BUN, NetworkedIds.Scene.PATTY, NetworkedIds.Scene.TOMATO, NetworkedIds.Scene.TOP_BUN]
	var multi_holder = create_multiholder(1)
	var combined_food_holder = create_combined_food(combined_food)
	multi_holder.hold_item(combined_food_holder)
	assert_eq(multi_holder.get_held_items().size(), 1, "Multiholder is holding more than one thing")
	
	var ev = [multi_holder.SCENE_ID]
	ev.append_array(combined_food)

	_menu_item.dish_display_holder.hold_item(multi_holder)

	# Act
	var main = _menu.menu_items[0].dish

	# Assert
	assert_eq(main, ev, "menu dish had something different")


func test_extracts_scene_ids_from_one_food():
	# Arrange
	var patty = NetworkedScenes.get_scene_by_id(NetworkedIds.Scene.PATTY).instantiate()
	_menu_item.dish_display_holder.hold_item(patty)
	
	# Act
	var main = _menu.menu_items[0].dish
	
	# Assert
	assert_eq(main, [NetworkedIds.Scene.PATTY], "menu dish had something different")

func test_extracts_scene_ids_from_one_drink():
	# Arrange
	var drink = NetworkedScenes.get_scene_by_id(NetworkedIds.Scene.CUP).instantiate()
	_menu_item.dish_display_holder.hold_item(drink)
	
	# Act
	var main = _menu.menu_items[0].dish
	
	# Assert
	assert_eq(main, [NetworkedIds.Scene.CUP], "menu dish had something different")

func test_order_for_drink_is_specific_to_a_beverage():
	# Arrange
	var drink_fountain : DrinkFountain = load("res://Scenes/drink_fountain.tscn").instantiate()
	add_child_autoqfree(drink_fountain)
	
	var dispenser = drink_fountain.dispensers[0]
	dispenser.beverage = NetworkedResources.get_resource_by_id(NetworkedIds.Resources.WATER)
	
	_menu._on_new_orderable(drink_fountain) # Setup the available drinks
	
	var drink : Drink = NetworkedScenes.get_scene_by_id(NetworkedIds.Scene.CUP).instantiate()
	add_child_autoqfree(drink)
	drink.fill(1.0, dispenser.beverage)
	assert_eq(drink.beverage_amounts[dispenser.beverage], 1.0, "Drink isn't full of beverage")
	
	_menu_item.dish_display_holder.hold_item(drink) # Sets menu to a single drink
	var main = _menu.menu_items[0].dish
	assert_eq(main, [NetworkedIds.Scene.CUP], "menu had something unexpected")
	
	# Act
	var order = _menu.generate_order_for(autofree(Customer.new()))
	
	# Assert
	assert_eq(order.scene_flattened_ids, [NetworkedIds.Scene.CUP], "Scenes dont match")
	assert_eq(order.resource_flattened_ids, [NetworkedIds.Resources.WATER], "Resources dont match")
