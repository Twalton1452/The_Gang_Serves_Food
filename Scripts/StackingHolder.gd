extends Holder
class_name StackingHolder

@export var ingredient_scene : PackedScene
@export var max_amount = 99
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)
@export var is_organized = false

func _ready():
	var i : int = 1
	var held_items = get_held_items()
	while i < len(held_items):
		var held_item = held_items[i]
		held_item.position = held_items[i - 1].position + (held_item.stacking_spacing if held_item is Food else stacking_spacing)
		i += 1

# Overriding Holder method for Right click stacking in Holder
func has_space_for_item(item: Node3D) -> bool:
	var acceptable_item = ingredient_scene == null or item != null and item.scene_file_path == ingredient_scene.resource_path
	return acceptable_item and len(get_held_items()) < max_amount

func hold_item(item: Node3D):
	if is_holding(item):
		return
	
	var held_items = get_held_items()
	if len(held_items) < max_amount:
		super(item)
		
		if is_organized:
			organize_items()
		else:
			if len(held_items) > 1:
				item.position = held_items[-1].position + item.stacking_spacing if item is Food else stacking_spacing
			else:
				item.position = Vector3.ZERO

func organize_items():
	var held_items = get_held_items()
	# Check for everything to be organizable first
	for held_item in held_items:
		if not held_item is Food:
			return
	
	# Sort according to the Rule's set in the Editor for that Scene
	(held_items as Array[Food]).sort_custom(func(a,b):
		if a.rule < b.rule:
			return 1
		return 0
	)
	
	# Establish a base
	# move_child doesn't really matter too much, but it'll be organized
	move_child(held_items[0], 0)
	held_items[0].position = Vector3.ZERO
	
	# Move the rest of the children according to the newly sorted array
	var i : int = 1
	while i < len(held_items):
		var held_item = held_items[i]
		move_child(held_item, i)
		held_item.position = held_items[i - 1].position + held_item.stacking_spacing
		i += 1

func _interact(player : Player):
	# Player Taking Item from this Holder
	if not player.c_holder.is_holding_item():
		# We have something to give the Player
		if is_holding_item():
			release_item_to(player.c_holder)
	# Player is holding a Plate, put this onto it
	elif player.c_holder.get_held_item() is MultiHolder:
		var multi_h : MultiHolder = player.c_holder.get_held_item()
		if is_holding_item():
			release_item_to(multi_h)
		
		if not multi_h.is_holding_item():
			if ingredient_scene == null:
				player.c_holder.release_item_to(self)
			# Taking Player's item if it matches
			elif multi_h.scene_file_path == ingredient_scene.resource_path:
				player.c_holder.release_item_to(self)
	# Taking Player's item no matter what
	elif ingredient_scene == null:
		player.c_holder.release_item_to(self)
	# Taking Player's item if it matches
	elif player.c_holder.get_held_item().scene_file_path == ingredient_scene.resource_path:
		player.c_holder.release_item_to(self)
