extends AIBody
class_name Customer

signal player_interacted_with
signal got_order
signal ate_food

@onready var interactable : Interactable = $Interactable

var target_chair : Chair = null
var sitting_chair : Chair = null : set = set_chair
var order : Array[NetworkedIds.Scene] : set = set_order

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	(get_parent() as CustomerParty).sync_customer(self)
	
	var is_interactable = reader.read_bool()
	if is_interactable:
		interactable.enable_collider()
	else:
		interactable.disable_collider()
	
	var has_target_chair = reader.read_bool()
	if has_target_chair:
		var chair = reader.read_path_to()
		target_chair = get_node(chair)
	
	var is_sitting = reader.read_bool()
	if is_sitting:
		var chair = reader.read_path_to()
		sitting_chair = get_node(chair)
		sit()
	
	var has_order = reader.read_bool()
	if has_order:
		var to_be_order : Array[int] = reader.read_int_array()
		order = to_be_order as Array[NetworkedIds.Scene]
		evaluate_food()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	
	writer.write_bool(interactable.is_enabled())
	
	var has_target_chair = target_chair != null
	var is_sitting = sitting_chair != null
	
	writer.write_bool(has_target_chair)
	if has_target_chair:
		writer.write_path_to(target_chair)
	
	writer.write_bool(is_sitting)
	if is_sitting:
		writer.write_path_to(sitting_chair)
		
	var has_order = order.size() > 0
	writer.write_bool(has_order)
	if has_order:
		writer.write_int_array(order as Array[int])
	return writer

func set_order(value) -> void:
	# customer has new order
	if len(value) > 0:
		interactable.enable_collider()
	# resetting customer order
	else:
		interactable.disable_collider()
	order = value

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
	if get_node_or_null("MeshInstance3D") != null:
		$MeshInstance3D.set("surface_material_override/0", null)

func evaluate_food():
	if sitting_chair == null or not sitting_chair.holder.is_holding_item() or len(order) == 0 or interactable.is_enabled():
		return
		
	var item_on_the_table = sitting_chair.holder.get_held_item()
	if not item_on_the_table is CombinedFoodHolder:
		return
		
	var foods = item_on_the_table.get_held_items()
	if order.size() != foods.size():
		return
	else:
		for i in len(foods):
			if (foods[i] as Food).SCENE_ID != order[i]:
				return
		got_order.emit()
		# Don't let the player interact with the food while the customer is about to eat
		sitting_chair.holder.disable_collider()
		sitting_chair.holder.get_held_item().disable_collider()
		for food in foods:
			(food as Food).disable_collider()

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
		
	var food = sitting_chair.holder.get_held_item()
	if not food is CombinedFoodHolder:
		print_debug("The food is not a CombinedFoodHolder, IDK what this is eating")
		return
	
	NetworkingUtils.send_item_for_deletion(food)

func sit():
	if target_chair:
		sitting_chair = target_chair
		sitting_chair.sit(self)
