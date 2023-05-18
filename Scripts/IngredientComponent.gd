extends HolderComponent
class_name IngredientComponent

@export var ingredient_scene : PackedScene
@export var max_amount = 99
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)

func has_space_for_item(item: Node3D) -> bool:
	var acceptable_item = ingredient_scene == null or item != null and item.scene_file_path == ingredient_scene.resource_path
	return acceptable_item and len(get_held_items()) < max_amount

func hold_item(item: Node3D):
	if is_holding(item):
		return
	
	if get_child_count() < max_amount:
		super(item)
		# 2 to account for CollisionShape3D
		if get_child_count() > 2:
			item.position = get_child(-2).position + stacking_spacing
		else:
			item.position = Vector3.ZERO
		

func interact(player : Player):
	# Player Taking Item from this Holder
	if not player.c_holder.is_holding_item():
		# We have something to give the Player
		if is_holding_item():
			release_item_to(player.c_holder)
	# Player is holding a Plate, put this onto it
	elif player.c_holder.get_held_item() is MultiHolderComponent:
		if is_holding_item():
			release_item_to(player.c_holder.get_held_item())
		
		if not player.c_holder.get_held_item().is_holding_item():
			if ingredient_scene == null:
				player.c_holder.release_item_to(self)
			# Taking Player's item if it matches
			elif player.c_holder.get_held_item().scene_file_path == ingredient_scene.resource_path:
				player.c_holder.release_item_to(self)
	# Taking Player's item no matter what
	elif ingredient_scene == null:
		player.c_holder.release_item_to(self)
	# Taking Player's item if it matches
	elif player.c_holder.get_held_item().scene_file_path == ingredient_scene.resource_path:
		player.c_holder.release_item_to(self)
