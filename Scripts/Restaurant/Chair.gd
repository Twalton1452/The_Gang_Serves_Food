extends Node3D
class_name Chair

@export var sitting_location : Node3D
@export var transition_location : Node3D
@export var holder : Holder
var sitter : Node3D = null

func sit(customer: Node3D) -> void:
	if sitter != null:
		print("they sittin in mah fuckin chair m8")
		return
	
	sitter = customer
#	if sitter.get_node_or_null("CollisionShape3D") != null:
#		sitter.get_node("CollisionShape3D").set_deferred("disabled", true)
#		await get_tree().physics_frame
	sitter.look_at_from_position(sitting_location.global_position, get_parent().global_position, Vector3.UP)
	sitter.rotation.x = 0
	sitter.rotation.z = 0

func force_sitter_out() -> void:
	if sitter == null:
		return
	sitter.look_at_from_position(transition_location.global_position, sitting_location.global_position, Vector3.UP)
	#sitter.rotationy = -sitter.rotation.y
#	if sitter.get_node_or_null("CollisionShape3D") != null:
#		sitter.get_node("CollisionShape3D").set_deferred("disabled", false)
	sitter = null
