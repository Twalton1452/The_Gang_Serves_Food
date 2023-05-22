extends Holder
class_name StackingHolder

@export var ingredient_scene : PackedScene
@export var max_amount = 99
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)

func set_sync_state(value: PackedByteArray):
	super(value)
	stack_items()

func _ready():
	stack_items()

func acceptable_item(item: Node3D) -> bool:
	return (ingredient_scene == null and not item is MultiHolder) or (item != null and ingredient_scene != null and item.scene_file_path == ingredient_scene.resource_path)

func has_space_for_item(item: Node3D) -> bool:
	return acceptable_item(item) and len(get_held_items()) < max_amount

func check_toggle_fallback_collider():
	if get_node_or_null("CollisionShape3D") != null:
		$CollisionShape3D.disabled = is_holding_item()

func hold_item(item: Node3D):
	if is_holding(item):
		return
	
	var held_items = get_held_items()
	if len(held_items) < max_amount:
		super(item)
		
		stack_items()
	
	check_toggle_fallback_collider()

func stack_items():
	var i : int = 1
	var held_items = get_held_items()
	while i < len(held_items):
		var held_item = held_items[i]
		held_item.position = held_items[i - 1].position + (held_items[i - 1].stacking_spacing if held_item is Food else stacking_spacing)
		i += 1
	
func release_this_item_to(item: Node3D, holder: Holder):
	super(item, holder)
	stack_items()
	check_toggle_fallback_collider()
	
func _interact(player : Player):
	# Player Taking Item from this Holder
	if not player.c_holder.is_holding_item():
		# We have something to give the Player
		if is_holding_item():
			release_item_to(player.c_holder)
	# Player is holding a Plate
	elif player.c_holder.get_held_item() is MultiHolder:
		var multi_h : MultiHolder = player.c_holder.get_held_item()
		
		# Player trying to put the item back onto this Stack
		if acceptable_item(multi_h):
			player.c_holder.release_item_to(self)
			return
		# Give Player the item from this Stack
		if is_holding_item():
			release_item_to(multi_h)
		# Taking Player's MultiHolder item if this stack can hold it
		if not multi_h.is_holding_item() and acceptable_item(multi_h):
			player.c_holder.release_item_to(self)
	# Take all of the Player's acceptable items in their Stack
	elif player.c_holder.get_held_item() is CombinedFoodHolder:
		var combined_food : CombinedFoodHolder = player.c_holder.get_held_item()
		var s_items = combined_food.get_held_items()
		for s_item in s_items:
			if acceptable_item(s_item):
				combined_food.release_this_item_to(s_item, self)
	# Taking Player's item if it matches with the pre-set ingredient_scene
	elif acceptable_item(player.c_holder.get_held_item()):
		player.c_holder.release_item_to(self)
