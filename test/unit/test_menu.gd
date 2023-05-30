extends TestingUtils

var _menu : Menu
var _menu_item : MenuItem

func before_each():
	var holder = Holder.new()
	add_child_autoqfree(holder)
	
	_menu_item = MenuItem.new()
	_menu_item.dish_holder = holder
	
	_menu = Menu.new()
	_menu.add_child(_menu_item)
	add_child_autoqfree(_menu)

func test_extracts_scene_ids_from_combined_food():
	# Arrange
	var ev : Array[SceneIds.SCENES] = [SceneIds.SCENES.BOTTOM_BUN, SceneIds.SCENES.PATTY, SceneIds.SCENES.TOMATO, SceneIds.SCENES.TOP_BUN]
	var combined_food_holder = create_combined_food(ev)
	
	_menu_item.dish_holder.hold_item(combined_food_holder)
	_menu_item._on_holder_changed()
	
	# Act
	var main = _menu.mains[0].dish
	
	# Assert
	assert_eq(main, ev, "main dish had something different")

#func test_extracts_scene_ids_from_multi_holder():
#	# Arrange
#	var ev : Array[SceneIds.SCENES] = [SceneIds.SCENES.BOTTOM_BUN, SceneIds.SCENES.PATTY, SceneIds.SCENES.TOMATO, SceneIds.SCENES.TOP_BUN]
#	var multi_holder = create_multiholder(1)
#	var combined_food_holder = create_combined_food(ev)
#	multi_holder.hold_item(combined_food_holder)
#
#	_menu_item.dish_holder.hold_item(multi_holder)
#
#	# Act
#	var main = _menu.mains[0].dish
#
#	# Assert
#	assert_eq(main, ev, "main dish had something different")


func test_extracts_scene_ids_from_side_one_dish_holder():
	pending()

func test_extracts_scene_ids_from_side_two_dish_holder():
	pending()
