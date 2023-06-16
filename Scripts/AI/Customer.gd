extends AIBody
class_name Customer

signal player_interacted_with
signal got_order
signal ate_food

@onready var pixel_face : PixelFace = $PixelFace
@onready var interactable : Interactable = $Interactable

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
	
	interactable.set_sync_state(reader)

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
		
	interactable.get_sync_state(writer)
	
	return writer

func set_order(value) -> void:
	order = value
	
	if order == null:
		return
	
	if sitting_chair == null:
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
	interactable.interacted.connect(_on_player_interacted)
	interactable.secondary_interacted.connect(_on_player_interacted)

func _exit_tree():
	if sitting_chair != null and sitting_chair.holder.interacted.is_connected(evaluate_food):
		sitting_chair.holder.interacted.disconnect(evaluate_food)
		sitting_chair.holder.secondary_interacted.disconnect(evaluate_food)
	Utils.cleanup_material_overrides(self)

func evaluate_food():
	if sitting_chair == null or not sitting_chair.holder.is_holding_item() or order == null or interactable.is_collider_enabled():
		return
		
	var item_on_the_table = sitting_chair.holder.get_held_item()
	if not order.is_equal_to(item_on_the_table):
		return
		
	got_order.emit()
	hide_order_visual()
	# Don't let the player interact with the food while the customer is about to eat
	Interactable.disable_colliders_for(sitting_chair.holder)

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
	
	# Send the consumables for deletion
	if dish is MultiHolder:
		for consumable in dish.get_held_items():
			if consumable is Drink:
				consumable.gulp()
				NetworkingUtils.send_partial_state_update(consumable)
			else:
				NetworkingUtils.send_item_for_deletion(consumable)
	elif dish is Drink:
		dish.gulp()
		NetworkingUtils.send_partial_state_update(dish)
	else:
		NetworkingUtils.send_item_for_deletion(dish)

func finished_eating() -> void:
	interactable.enable_collider()
	Interactable.enable_colliders_for(sitting_chair.holder)

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
