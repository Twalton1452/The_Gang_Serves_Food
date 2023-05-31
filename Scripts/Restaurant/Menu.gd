extends Node3D
class_name Menu

signal new_menu(menu: Menu)

var main_items : Array[MenuItem] = []
#var sides : Array[MenuItem] = []

func _ready():
	_on_menu_item_changed()

func _on_menu_item_changed():
	for menu_item in main_items:
		if (menu_item as MenuItem).changed.is_connected(_on_menu_item_changed):
			(menu_item as MenuItem).changed.disconnect(_on_menu_item_changed)
	
	main_items.clear()
	var menu_items = get_children().filter(func(c): return c is MenuItem)
	for menu_item in menu_items:
		(menu_item as MenuItem).changed.connect(_on_menu_item_changed)
		main_items.push_back(menu_item)
	
	new_menu.emit(self)

func is_menu_available() -> bool:
	return not main_items.is_empty() and main_items.any(func(menu_item): return menu_item.is_dish_available())

func generate_order_for(_customer: Customer) -> Array[SceneIds.SCENES]:
	# eventually going to take in customer preferences
	return main_items[0].dish
