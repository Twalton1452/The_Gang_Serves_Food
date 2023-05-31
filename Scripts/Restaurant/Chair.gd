extends Node3D
class_name Chair

@export var sitting_location : Node3D
@export var transition_location : Node3D
@export var holder : Holder
var sitter : Customer = null

func sit(customer: Customer) -> void:
	if sitter != null:
		print("they sittin in mah fuckin chair m8")
		return
	
	sitter = customer
	sitter.sitting_chair = self
	sitter.look_at_from_position(sitting_location.global_position, get_parent().global_position, Vector3.UP)
	sitter.rotation.x = 0
	sitter.rotation.z = 0

func force_sitter_out() -> void:
	if sitter == null:
		return
	sitter.sitting_chair = null
	sitter.global_position = transition_location.global_position
	sitter.rotation.x = 0
	sitter.rotation.z = 0
	sitter = null
	holder.enable_collider()
