extends CharacterBody3D
class_name AIBody

signal arrived

@export var go_to_target : Node3D
@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D

var speed = 1.0
var target_position = Vector3.ZERO

var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.CUSTOMER

func set_sync_state(reader: ByteReader) -> void:
	var sync_tar_pos = reader.read_vector3()
	var in_progress = reader.read_bool()
	rotation.y = reader.read_float()
	if in_progress:
		go_to(sync_tar_pos)
	else:
		disable_physics()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_vector3(target_position)
	writer.write_bool(!nav_agent.is_navigation_finished())
	writer.write_float(rotation.y)
	return writer

func _ready() -> void:
	nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))
	nav_agent.navigation_finished.connect(Callable(_on_navigation_finished))
	nav_agent.target_reached.connect(Callable(_on_target_reached))
	if go_to_target != null:
		go_to.call_deferred(go_to_target.global_transform.origin)
		
## Navigation needs to be in global space.
## Use [code]Node.global_transform.origin[/code] when passing values to this function
func go_to(movement_target: Vector3):
	enable_physics()
	target_position = movement_target
	nav_agent.set_target_position(movement_target)

func _physics_process(_delta):
	if nav_agent.is_navigation_finished():
		return

	var next_path_position: Vector3 = nav_agent.get_next_path_position()
	var current_agent_position: Vector3 = global_position
	var direction = (next_path_position - current_agent_position).normalized()
	var new_velocity: Vector3 = direction * speed
	if not nav_agent.is_target_reached():
		rotate_to(direction)
#		if not nav_agent.is_target_reachable():
#			print("%s can't reach its destination" % name)
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func rotate_to(look_at_pos: Vector3) -> void:
	# Subtract PI (180 degrees) because our forward direction is -Z instead of +Z
	var angle_in_rad = atan2(look_at_pos.x, look_at_pos.z) - PI
	rotation.y = angle_in_rad
	
## Used for when avoidance between other NavAgent's is enabled
func _on_velocity_computed(safe_velocity: Vector3):
	velocity = safe_velocity
	move_and_slide()

## Final position signal
func _on_navigation_finished():
	arrived.emit()
	#print("%s reached its destination!" % name)

## Not totally sure what the difference between this and the "navigation_finished" signals is
## I think this one will be emitted when certain waypoints along a path are hit?
func _on_target_reached():
	#print("reached target")
	pass

func disable_physics():
	set_physics_process(false)

func enable_physics():
	set_physics_process(true)

func _unhandled_input(event):
	if event is InputEventKey and event.is_action_pressed("debug_pathing"):
		nav_agent.debug_enabled = !nav_agent.debug_enabled
