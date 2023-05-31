extends AIBody
class_name Customer

signal player_interacted_with
signal got_order
signal ate_food

@onready var interactable : Interactable = $Interactable

var sitting_chair : Chair = null : set = set_chair
var order : Array[SceneIds.SCENES]

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	(get_parent() as CustomerParty).sync_customer(self)
	var has_order = reader.read_bool()
	if has_order:
		var to_be_order : Array[int] = reader.read_int_array()
		order = []
		for item in to_be_order:
			order.push_back(item)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	var has_order = order.size() > 0
	writer.write_bool(has_order)
	if has_order:
		writer.write_int_array(order as Array[int])
	return writer

func _ready():
	interactable.interacted.connect(_on_player_interacted)
	interactable.secondary_interacted.connect(_on_player_interacted)

func _exit_tree():
	if sitting_chair != null and sitting_chair.holder.interacted.is_connected(evaluate_food):
		sitting_chair.holder.interacted.disconnect(evaluate_food)
		sitting_chair.holder.secondary_interacted.disconnect(evaluate_food)

func set_chair(value: Chair):
	if sitting_chair != null and sitting_chair.holder.interacted.is_connected(evaluate_food):
		sitting_chair.holder.interacted.disconnect(evaluate_food)
		sitting_chair.holder.secondary_interacted.disconnect(evaluate_food)
	
	sitting_chair = value
	if sitting_chair != null:
		sitting_chair.holder.interacted.connect(evaluate_food)
		sitting_chair.holder.secondary_interacted.connect(evaluate_food)

func evaluate_food():
	if not sitting_chair.holder.is_holding_item():
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

func order_from(menu: Menu):
	if not is_multiplayer_authority():
		return
	
	order = menu.main_items[0].dish
	#print("Order is %s" % [order])
	
	var writer = ByteWriter.new()
	writer.write_int_array(order as Array[int])
	notify_peers_of_order.rpc(writer.data)
	interactable.enable_collider()

@rpc("authority")
func notify_peers_of_order(order_data: PackedByteArray):
	var reader = ByteReader.new(order_data)
	var to_be_order : Array[int] = reader.read_int_array()
	order = []
	for item in to_be_order:
		order.push_back(item)
	interactable.enable_collider()
	#print("%s sent me (%s) an order %s" % [multiplayer.get_remote_sender_id(), multiplayer.get_unique_id(), order])

func _on_player_interacted() -> void:
	player_interacted_with.emit()
	interactable.disable_collider()

func eat() -> void:
	interactable.enable_collider()
	ate_food.emit()
	if not is_multiplayer_authority():
		return
	
	if not sitting_chair.holder.is_holding_item():
		print_debug("The food should be there, but it isnt. I'm trying to delete it")
		return
		
	var food = sitting_chair.holder.get_held_item()
	if not food is CombinedFoodHolder:
		print_debug("The food is not a CombinedFoodHolder, IDK what this is eating")
		return
	
	NetworkingUtils.send_item_for_deletion(food)
	
