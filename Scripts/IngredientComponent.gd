extends Node3D
class_name IngredientComponent

@export var ingredient_scene : PackedScene
@export var ingredient_parent : Node3D
@export var max_amount = 99
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)

func take_ingredient() -> Node3D:
	if ingredient_parent != null and ingredient_parent.get_child_count() > 0:
		return ingredient_parent.get_child(ingredient_parent.get_child_count() - 1)
	return null

func put_ingredient_down(ingredient: Node3D) -> void:
	var parent = ingredient_parent if ingredient_parent != null else self
	if parent.get_child_count() < max_amount:
		ingredient.reparent(parent, false)
		if parent.get_child_count() > 2:
			ingredient.position = parent.get_child(-2).position + stacking_spacing
		else:
			ingredient.position = Vector3.ZERO
		

func _on_interactable_component_interacted(_node : InteractableComponent, player : Player):
	if not player.is_holding_item():

		var holdable = take_ingredient().get_node("HoldableComponent")
		if holdable is HoldableComponent:
			holdable.hold(player.name)
	elif player.get_held_item().scene_file_path == ingredient_scene.resource_path:
		put_ingredient_down(player.get_held_item())
	else:
		print("This isn't the same item, can't put it back: %s" % player.get_held_item().scene_file_path)
