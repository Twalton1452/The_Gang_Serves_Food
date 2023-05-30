extends Node3D
class_name Menu

var mains : Array[MenuItem] = []
#var sides : Array[MenuItem] = []

func _ready():
	_on_menu_item_changed()

func _on_menu_item_changed():
	for menu_item in mains:
		if (menu_item as MenuItem).changed.is_connected(_on_menu_item_changed):
			(menu_item as MenuItem).changed.disconnect(_on_menu_item_changed)
	
	mains.clear()
	var menu_items = get_children().filter(func(c): return c is MenuItem)
	for menu_item in menu_items:
		(menu_item as MenuItem).changed.connect(_on_menu_item_changed)
		mains.push_back(menu_item)
