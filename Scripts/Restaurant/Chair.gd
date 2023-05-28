extends Node3D
class_name Chair

@export var sitting_location : Node3D
@export var transition_location : Node3D
var sitter : Node3D = null

func sit(customer: Node3D) -> void:
	if sitter != null:
		return
	
	sitter = customer
	if sitter.get_node_or_null("CollisionShape3D") != null:
		sitter.get_node("CollisionShape3D").set_deferred("disabled", true)
		await get_tree().physics_frame
	sitter.global_position = sitting_location.global_position

func force_sitter_out() -> void:
	if sitter == null:
		return
	
	sitter.global_position = transition_location.global_position
	if sitter.get_node_or_null("CollisionShape3D") != null:
		sitter.get_node("CollisionShape3D").set_deferred("disabled", false)
	sitter = null
