extends Node3D
class_name Chair

@export var sitting_location : Node3D
@export var transition_location : Node3D
@export var holder : Holder
var sitter : Node3D = null
var sittable = true : set = set_sittable

func set_sittable(value: bool) -> void:
	visible = value
	sittable = value

func _exit_tree():
	Utils.cleanup_material_overrides(self)

func sit(to_be_seated: Node3D) -> void:
	if sitter != null:
		print("they sittin in mah fuckin chair m8")
		return
	
	sitter = to_be_seated
	if "sitting_chair" in sitter:
		sitter.sitting_chair = self
	sitter.look_at_from_position(sitting_location.global_position, get_parent().global_position, Vector3.UP)
	sitter.rotation.x = 0
	sitter.rotation.z = 0

func force_sitter_out() -> void:
	if sitter == null:
		return
	if "sitting_chair" in sitter:
		sitter.sitting_chair = null
	sitter.global_position = transition_location.global_position
	sitter.rotation.x = 0
	sitter.rotation.z = 0
	sitter = null
	holder.enable_collider()
