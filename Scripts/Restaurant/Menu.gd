extends Node3D
class_name Menu

signal new_menu(menu: Menu)

@export var orders_parent : Node3D

var menu_items : Array[MenuItem] = []

func _ready():
	watch_for_changes_to_menu_items()

func watch_for_changes_to_menu_items():
	var child_menu_items = get_children().filter(func(c): return c is MenuItem)
	for menu_item in child_menu_items:
		if not menu_item.changed.is_connected(_on_menu_item_changed):
			(menu_item as MenuItem).changed.connect(_on_menu_item_changed)
			menu_items.push_back(menu_item)
	_on_menu_item_changed()
	
func _on_menu_item_changed():
	new_menu.emit(self)

func is_menu_available() -> bool:
	return not menu_items.is_empty() and menu_items.any(func(menu_item): return menu_item.is_dish_available())

func generate_order_for(customer: Customer) -> Order:
	if not is_multiplayer_authority():
		return
	
	if not is_menu_available():
		return null
	
	var order : Order = NetworkingUtils.spawn_node_for_everyone(NetworkedScenes.get_scene_by_id(NetworkedIds.Scene.ORDER), orders_parent)
	var duplicated_dish = NetworkingUtils.duplicate_node_for_everyone(menu_items[0].dish_display_holder.get_held_item(), order, true)
	
	order.init(duplicated_dish)
	customer.order = order
	return order
