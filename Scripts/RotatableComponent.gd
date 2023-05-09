extends Node3D
class_name RotatableComponent

## Set in degrees, but converted to radians on _ready for the Tween
@export var tar_rot = Vector3(0.0, -90.0, 0.0)

var og_rot : Vector3

var is_rotated = false
var in_progress = false

func _ready():
	og_rot = get_parent().rotation
	tar_rot.x = deg_to_rad(tar_rot.x)
	tar_rot.y = deg_to_rad(tar_rot.y)
	tar_rot.z = deg_to_rad(tar_rot.z)

func _on_interactable_component_interacted(node, _player):
	rotate_parent(node)

func rotate_parent(node):
	if in_progress:
		return
	in_progress = true

	var t = create_tween()
	if is_rotated:
		t.tween_property(node.get_parent(), "rotation", og_rot, 0.3).set_ease(Tween.EASE_IN)
	else:
		t.tween_property(node.get_parent(), "rotation", tar_rot, 0.3).set_ease(Tween.EASE_OUT)

	await t.finished
	in_progress = false
	is_rotated = !is_rotated
