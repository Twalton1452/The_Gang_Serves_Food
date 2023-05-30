extends Node
class_name OrderGenerator

func generate_order(menu_board: MenuBoard):
	var order = Order.new()
	order.main = generate_main_dish(menu_board.main_dish)
	order.side_one = generate_side_dish(menu_board.side_one)
	order.side_two = generate_side_dish(menu_board.side_two)
	return order

func generate_main_dish(ids: Array[SceneIds.SCENES]):
	pass

func generate_side_dish(ids: Array[SceneIds.SCENES]):
	pass

func generate_random_dish(ids: Array[SceneIds.SCENES]):
	pass

class Order:
	var main : Array[SceneIds.SCENES]
	var side_one : Array[SceneIds.SCENES]
	var side_two : Array[SceneIds.SCENES]
