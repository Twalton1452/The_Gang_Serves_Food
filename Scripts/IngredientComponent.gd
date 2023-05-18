extends HolderComponent
class_name IngredientComponent

@export var ingredient_scene : PackedScene
@export var max_amount = 99
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)

# Overriding Holder method for Right click stacking in HolderComponent
func has_space_for_item(item: Node3D) -> bool:
	var acceptable_item = ingredient_scene == null or item != null and item.scene_file_path == ingredient_scene.resource_path
	return acceptable_item and len(get_held_items()) < max_amount

func hold_item(item: Node3D):
	if is_holding(item):
		return
	
	var held_items = get_held_items()
	if len(held_items) < max_amount:
		super(item)
		# 2 to account for CollisionShape3D
		if len(held_items) > 1:
			item.position = held_items[-1].position + stacking_spacing
		else:
			item.position = Vector3.ZERO
		

func _interact(player : Player):
	# Player Taking Item from this Holder
	if not player.c_holder.is_holding_item():
		# We have something to give the Player
		if is_holding_item():
			release_item_to(player.c_holder)
	# Player is holding a Plate, put this onto it
	elif player.c_holder.get_held_item() is MultiHolderComponent:
		var multi_h : MultiHolderComponent = player.c_holder.get_held_item()
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
