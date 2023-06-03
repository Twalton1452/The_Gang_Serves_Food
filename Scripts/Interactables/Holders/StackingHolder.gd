extends Holder
class_name StackingHolder

@export var ingredient_scene : PackedScene
@export var max_amount = 99
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)

func after_sync() -> void:
	stack_items.call_deferred()

func _ready():
	super()
	stack_items.call_deferred()
	
	# Disable the child colliders on the MultiHolder's Holder's
	# So things like Plate's can't be given food while they are stacked
	var i : int = 0
	var held_items = get_held_items()
	while i < len(held_items):
		var held_item = held_items[i]
		if held_item is MultiHolder:
			held_item.disable_colliders()
		i += 1
	
func acceptable_item(item: Node3D) -> bool:
	# Accept any item as long as its not a MultiHolder
	if ingredient_scene == null and not item is MultiHolder:
		return true
	# Accept the item set by the Editor
	if item != null and ingredient_scene != null and item.scene_file_path == ingredient_scene.resource_path:
		# Only put MultiHolders back if they are empty
		if item is MultiHolder:
			return not item.is_holding_item()
		return true
	return false

func has_space_for_item(item: Node3D) -> bool:
	return acceptable_item(item) and len(get_held_items()) < max_amount

func check_toggle_fallback_collider():
	if is_holding_item():
		disable_collider()
	else:
		enable_collider()

func hold_item(item: Node3D):
	if is_holding(item):
		return
	
	var held_items = get_held_items()
	if len(held_items) < max_amount:
		super(item)
		
		if item is MultiHolder:
			item.disable_colliders()
		
		stack_items()
	
	check_toggle_fallback_collider()

func stack_items():
	var i : int = 1
	var held_items = get_held_items()
	
	if len(held_items) > 0:
		held_items[0].position = Vector3.ZERO
	
	while i < len(held_items):
		var held_item = held_items[i]
		held_item.position = held_items[i - 1].position + (held_items[i - 1].stacking_spacing if held_item is Food else stacking_spacing)
		i += 1
	
func release_this_item_to(item: Node3D, holder: Holder):
	super(item, holder)
	stack_items()
	check_toggle_fallback_collider()
	if item is MultiHolder and item.get_parent() == holder:
		item.enable_colliders()
	
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

func disable_held_colliders():
	for item in get_held_items():
		item.disable_collider()

func enable_held_colliders():
	for item in get_held_items():
		item.enable_collider()
