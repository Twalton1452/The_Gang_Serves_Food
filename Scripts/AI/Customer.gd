extends CharacterBody3D
class_name Customer

@export var go_to_target : Node3D
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D

var speed = 1.0

func _ready():
	if go_to_target != null:
		update_target_location.call_deferred(go_to_target.global_transform.origin)

func _physics_process(_delta):
	if nav_agent.is_navigation_finished():
		return
	
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var direction = (next_location - current_location).normalized()
#	if not nav_agent.is_target_reached():
#		look_at(position + direction)

	var new_velocity = direction * speed
	
	velocity = new_velocity
	move_and_slide()

## Navigation needs to be in global space.
## Use [code]Node.global_transform.origin[/code] when passing values to this function
func update_target_location(target_location : Vector3):
	nav_agent.target_position = target_location

func _on_navigation_agent_3d_target_reached():
	#pass
	print("%s reached its destination!" % name)


func _on_navigation_agent_3d_navigation_finished():
	#pass
	print("finished navigation")
