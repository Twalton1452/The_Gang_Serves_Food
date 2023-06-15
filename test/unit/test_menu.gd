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
	
	_menu = Menu.new()
	_menu.add_child(_menu_item)
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
