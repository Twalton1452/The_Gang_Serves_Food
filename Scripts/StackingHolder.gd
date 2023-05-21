extends Holder
class_name StackingHolder

@export var ingredient_scene : PackedScene
@export var max_amount = 99
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)
@export var is_organized = false
@export var destroy_on_empty = false

func _ready():
	var i : int = 1
	var held_items = get_held_items()
	while i < len(held_items):
		var held_item = held_items[i]
		held_item.position = held_items[i - 1].position + (held_items[i - 1].stacking_spacing if held_item is Food else stacking_spacing)
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
		
		stack_items()
	# Don't need the fall back collider if we can interact with the items on the Holder
	if get_node_or_null("CollisionShape3D") != null:
		$CollisionShape3D.disabled = true

func stack_items():
	var held_items = get_held_items()
	if len(held_items) > 1:
		var new_item = held_items[-1]
		new_item.position = held_items[-2].position + held_items[-2].stacking_spacing if held_items[-2] is Food else stacking_spacing
#	else:
#		new_item.position = Vector3.ZERO

func release_item_to(holder: Holder):
	super(holder)
	if len(get_held_items()) == 0:
		# Fall back collider so you can still stack when no items are there
		if get_node_or_null("CollisionShape3D") != null:
			$CollisionShape3D.disabled = false
	
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
