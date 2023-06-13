extends AIBody
class_name Customer

signal player_interacted_with
signal got_order
signal ate_food

@onready var pixel_face : PixelFace = $PixelFace
var interactable : Interactable = null

var target_chair : Chair = null
var sitting_chair : Chair = null : set = set_chair
var order : Order : set = set_order

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	(get_parent() as CustomerParty).sync_customer(self)
	
	var has_target_chair = reader.read_bool()
	if has_target_chair:
		var chair = reader.read_path_to()
		target_chair = get_node(chair)
	
	var is_sitting = reader.read_bool()
	if is_sitting:
		var chair = reader.read_path_to()
		sitting_chair = get_node(chair)
		target_chair = sitting_chair
		sit()
	
	var has_order = reader.read_bool()
	if has_order:
		order = get_node(reader.read_path_to())

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	
	var has_target_chair = target_chair != null
	var is_sitting = sitting_chair != null
	
	writer.write_bool(has_target_chair)
	if has_target_chair:
		writer.write_path_to(target_chair)
	
	writer.write_bool(is_sitting)
	if is_sitting:
		writer.write_path_to(sitting_chair)
	
	var has_order = order != null
	writer.write_bool(has_order)
	if has_order:
		writer.write_path_to(order)
	return writer

func set_order(value) -> void:
	order = value
	
	if order == null:
		return
	
	order.global_position = sitting_chair.holder.global_position
	evaluate_food()

func set_chair(value: Chair):
	if sitting_chair != null and sitting_chair.holder.interacted.is_connected(evaluate_food):
		sitting_chair.holder.interacted.disconnect(evaluate_food)
		sitting_chair.holder.secondary_interacted.disconnect(evaluate_food)
	
	sitting_chair = value
	if sitting_chair != null:
		disable_physics()
		sitting_chair.holder.interacted.connect(evaluate_food)
		sitting_chair.holder.secondary_interacted.connect(evaluate_food)
	else:
		enable_physics()

func _ready():
	super()
	for child in get_children():
		if child is Interactable:
			interactable = child
			break
	interactable.interacted.connect(_on_player_interacted)
	interactable.secondary_interacted.connect(_on_player_interacted)

func _exit_tree():
	if sitting_chair != null and sitting_chair.holder.interacted.is_connected(evaluate_food):
		sitting_chair.holder.interacted.disconnect(evaluate_food)
		sitting_chair.holder.secondary_interacted.disconnect(evaluate_food)
	Utils.cleanup_material_overrides(self)

func evaluate_food():
	if sitting_chair == null or not sitting_chair.holder.is_holding_item() or order == null or interactable.is_enabled():
		return
		
	var item_on_the_table = sitting_chair.holder.get_held_item()
	if not order.is_equal_to(item_on_the_table):
		return
		
	got_order.emit()
	hide_order_visual()
	# Don't let the player interact with the food while the customer is about to eat
	sitting_chair.holder.disable_collider()
	if item_on_the_table is MultiHolder:
		item_on_the_table.disable_colliders()
		for held_item in item_on_the_table.get_held_items():
			held_item.disable_collider()
	elif item_on_the_table is CombinedFoodHolder:
		item_on_the_table.disable_held_colliders()
	else:
		item_on_the_table.disable_collider()

func order_from(menu: Menu):
	if not is_multiplayer_authority():
		return
	
	order = menu.generate_order_for(self)
	#print("Order is %s" % [order])

func _on_player_interacted() -> void:
	player_interacted_with.emit()
	interactable.disable_collider()

func eat() -> void:
	if not is_multiplayer_authority():
		return
	ate_food.emit()
	
	if not sitting_chair.holder.is_holding_item():
		print_debug("The food should be there, but it isnt. I'm trying to delete it")
		return
		
	var dish = sitting_chair.holder.get_held_item()
	
	# Send the items on the MultiHolder for deletion but not the MultiHolder
	if dish is MultiHolder:
		for held_item in dish.get_held_items():
			NetworkingUtils.send_item_for_deletion(held_item)
		dish.enable_colliders()
	else:
		NetworkingUtils.send_item_for_deletion(dish)

func sit():
	if target_chair != null:
		sitting_chair = target_chair
	if sitting_chair != null:
		sitting_chair.sit(self)

func show_order_visual():
	if order != null:
		order.show()

func hide_order_visual():
	if order != null:
		order.hide()

func delete_order():
	if not is_multiplayer_authority():
		return
	
	NetworkingUtils.send_item_for_deletion(order)
