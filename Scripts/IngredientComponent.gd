extends Node3D
class_name IngredientComponent

@export var ingredient_scene : PackedScene
@export var ingredient_parent : Node3D


func take_ingredient() -> Node3D:
	if ingredient_parent != null and ingredient_parent.get_child_count() > 0:
		return ingredient_parent.get_child(ingredient_parent.get_child_count() - 1)
	return


func _on_interactable_component_interacted(node : InteractableComponent, player : Player):
	if not player.is_holding_item():
		var ingredient = take_ingredient()
		player.hold_item(take_ingredient())
