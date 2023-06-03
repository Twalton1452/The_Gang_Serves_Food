extends Node
class_name Floater

@export_group("Movement")
@export var move_enabled = false
@export var move_amount = Vector3(0.0, -1.0, 0.0)

# Time it takes for the tween to complete
@export var move_to_target_seconds = 1.5
@export var move_to_original_seconds = 1.5

# Transition time before starting the next tween
@export var move_delay_to_target_seconds = 0.1
@export var move_delay_to_original_seconds = 0.1

@export var move_ease_to_target : Tween.EaseType = Tween.EASE_IN
@export var move_ease_to_original : Tween.EaseType = Tween.EASE_OUT

@export var move_transition_to_target : Tween.TransitionType = Tween.TRANS_LINEAR
@export var move_transition_to_original : Tween.TransitionType = Tween.TRANS_LINEAR


@export_group("Rotation")
@export var rotation_enabled = false
@export var rotation_target_degrees = Vector3(0.0, 360.0, 0.0)

# Time it takes for the tween to complete
@export var rotate_to_target_seconds = 3
@export var rotate_to_original_seconds = 3

# Transition time before starting the next tween
@export var rotate_delay_to_target_seconds = 0.1
@export var rotate_delay_to_original_seconds = 0.1

@export var rotate_ease_to_target : Tween.EaseType = Tween.EASE_IN
@export var rotate_ease_to_original : Tween.EaseType = Tween.EASE_OUT

@export var rotate_transition_to_target : Tween.TransitionType = Tween.TRANS_LINEAR
@export var rotate_transition_to_original : Tween.TransitionType = Tween.TRANS_LINEAR

var original_position : Vector3
var rotation_target_radians : Vector3
var original_rotation : Vector3
var tween : Tween = null

func _ready():
	loop.call_deferred()

func stop():
	if tween != null and tween.is_running():
		tween.stop()

func restart():
	stop()
	loop()

func loop():
	tween = create_tween()
	tween.set_loops(0)
	
	if move_enabled:
		original_position = get_parent().position
		tween.parallel().tween_property(get_parent(), "position", original_position + move_amount, move_to_target_seconds)\
			.set_ease(move_ease_to_original)\
			.set_delay(move_delay_to_original_seconds)\
			.set_trans(move_transition_to_original)
		
		tween.tween_property(get_parent(), "position", original_position, move_to_original_seconds)\
			.set_ease(move_ease_to_target)\
			.set_delay(move_delay_to_target_seconds)\
			.set_trans(move_transition_to_target)
	
	
	if rotation_enabled:
		original_rotation = get_parent().rotation
		rotation_target_radians = rotation_target_degrees
		rotation_target_radians.x = deg_to_rad(rotation_target_radians.x)
		rotation_target_radians.y = deg_to_rad(rotation_target_radians.y)
		rotation_target_radians.z = deg_to_rad(rotation_target_radians.z)
		
		tween.parallel().tween_property(get_parent(), "rotation", rotation_target_radians, move_to_target_seconds)\
			.set_ease(rotate_ease_to_target)\
			.set_delay(rotate_delay_to_target_seconds)\
			.set_trans(rotate_transition_to_target)
		
		tween.tween_property(get_parent(), "rotation", original_rotation, move_to_original_seconds)\
			.set_ease(rotate_ease_to_target)\
			.set_delay(rotate_delay_to_target_seconds)\
			.set_trans(rotate_transition_to_target)
