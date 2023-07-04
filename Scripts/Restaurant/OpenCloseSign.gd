extends Node3D
class_name OpenCloseSign

@export var rotatable : Rotatable

func _ready() -> void:
	rotatable.rotated.connect(_on_sign_rotated)
	if GameState.state == GameState.Phase.EDITING_RESTAURANT:
		rotatable.force_rotate_parent()

func _on_sign_rotated() -> void:
	if not is_multiplayer_authority():
		return
	
	if GameState.state == GameState.Phase.OPEN_FOR_BUSINESS:
		GameState.state = GameState.Phase.EDITING_RESTAURANT
	elif GameState.state == GameState.Phase.EDITING_RESTAURANT:
		GameState.state = GameState.Phase.OPEN_FOR_BUSINESS
