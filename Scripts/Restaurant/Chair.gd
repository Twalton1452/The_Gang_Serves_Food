extends Node3D
class_name Chair

@export var transition_location : Node3D
var sitter : Node3D = null

func sit(customer: Node3D) -> void:
	if sitter != null:
		return
	
	sitter = customer
	sitter.position = position

func force_sitter_out() -> void:
	if sitter == null:
		return
	
	sitter.position = transition_location.position
	sitter = null
