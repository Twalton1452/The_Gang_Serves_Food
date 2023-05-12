extends HolderComponent
class_name IngredientComponent

@export var ingredient_scene : PackedScene
@export var max_amount = 99
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)

func hold_item(item: Node3D):
	if is_holding(item):
		return
	
	if get_child_count() < max_amount:
		super(item)
		if get_child_count() > 2:
			item.position = get_child(-2).position + stacking_spacing
		else:
			item.position = Vector3.ZERO
		

func _on_interactable_component_interacted(_node : InteractableComponent, player : Player):
	# Player Taking Item from this Holder
	if not player.holder_component.is_holding_item():
		# Holder has something to give
		if is_holding_item():
			player.holder_component.hold_item(get_held_item())
			released_holding.emit(get_held_item())
	# Taking Player's item no matter what
	elif ingredient_scene == null:
		hold_item(player.holder_component.get_held_item())
	# Taking Player's item if it matches
	elif player.holder_component.get_held_item().scene_file_path == ingredient_scene.resource_path:
		hold_item(player.holder_component.get_held_item())
