extends AIBody
class_name Customer

signal player_interacted_with
signal got_order
signal ate_food

@onready var interactable : Interactable = $Interactable

var target_chair : Chair = null
var sitting_chair : Chair = null : set = set_chair
var order : Array[NetworkedIds.Scene] : set = set_order
var order_visual : CombinedFoodHolder = null

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
		var to_be_order : Array[int] = reader.read_int_array()
		order = to_be_order as Array[NetworkedIds.Scene]
		var showing_order_visual = reader.read_bool()
		if showing_order_visual:
			show_order_visual()
		evaluate_food()
	
	var is_interactable = reader.read_bool()
	if is_interactable:
		interactable.enable_collider()
	else:
		interactable.disable_collider()

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
		
	var has_order = order.size() > 0
	writer.write_bool(has_order)
	if has_order:
		writer.write_int_array(order as Array[int])
		var showing_order_visual = order_visual != null and order_visual.visible
		writer.write_bool(showing_order_visual)
	
	writer.write_bool(interactable.is_enabled())
	return writer

func set_order(value) -> void:
	order = value
	
	# customer has new order
	if len(order) > 0:
		interactable.enable_collider()
		spawn_hidden_order_visual()
	# resetting customer order
	else:
		interactable.disable_collider()

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
		delete_order_visual()
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

## We spawn the visual as the customer makes their order
## However we don't show it until a Player interaction happens
## Customer patiently waits for someone to ask them what they want before showing!
func spawn_hidden_order_visual():
	if order.size() == 0 or sitting_chair == null:
		return
	
	var combiner : CombinedFoodHolder = NetworkingUtils.spawn_client_only_node(NetworkedScenes.get_scene_by_id(NetworkedIds.Scene.FOOD_COMBINER), self)
	for id in order:
		var food : Food = NetworkingUtils.spawn_client_only_node(NetworkedScenes.get_scene_by_id(id), combiner)
		combiner.hold_item_unsafe(food)
		for i in range(food.obj_to_color.get_surface_override_material_count()):
			food.obj_to_color.get_active_material(i)
			food.material_to_color.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			food.material_to_color.albedo_color.a = 0.7
	combiner.stack_items()
	
	var floater = Floater.new()
	floater.move_enabled = true
	floater.move_amount = Vector3(0.0, 0.05, 0.0)
	floater.move_to_original_seconds = 1.3
	floater.move_to_target_seconds = 1.3
	floater.move_transition_to_target = Tween.TRANS_BACK
	floater.move_transition_to_target = Tween.TRANS_BACK
	combiner.add_child(floater)
	
	order_visual = combiner
	order_visual.global_position = sitting_chair.holder.global_position
	order_visual.disable_collider()
	order_visual.disable_held_colliders()
	order_visual.hide()

func show_order_visual():
	order_visual.show()

func delete_order_visual():
	if order_visual != null:
		order_visual.queue_free()

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
	if target_chair != null:
		sitting_chair = target_chair
	if sitting_chair != null:
		sitting_chair.sit(self)
