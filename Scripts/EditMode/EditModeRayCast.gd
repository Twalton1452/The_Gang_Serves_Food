extends RayCast3D

@onready var remote_transform : RemoteTransform3D = $RemoteTransform3D
@onready var uneditable_ray_cast : RayCast3D = $UneditableRayCast3D

var outline_material : StandardMaterial3D = preload("res://Materials/Grow_Outline_mat.tres")
var looking_at : Node3D = null
var lock_to = false : set = set_lock
var target : StaticBody3D = null
var snapping = Vector3(0.1,0.1,0.1)

func set_lock(value: bool) -> void:
	lock_to = value
	if lock_to:
		target = get_collider()
		set_child_collisions_for(target.owner, false)
	else:
		set_child_collisions_for(target.owner, true)
		target = null

func set_child_collisions_for(node: Node3D, value: bool) -> void:
	node.propagate_call("set_collision_layer_value", [1, value], true)
#	for child in node.get_children():
#		if child is StaticBody3D:
#			child.set_collision_layer_value(1, value)
#		set_child_collisions_for(child, value)

func enable():
	enabled = true
	uneditable_ray_cast.enabled = true

func disable():
	enabled = false
	uneditable_ray_cast.enabled = false
	if looking_at:
		hide_outline(looking_at)
	remote_transform.remote_path = ^""

func _unhandled_input(event):
	if event.is_action_pressed("ui_left"):
		enabled = !enabled
		if looking_at:
			hide_outline(looking_at)


func _physics_process(_delta):
	if not enabled:
		return
	
	if remote_transform.remote_path != ^"":
		if is_colliding():
			remote_transform.global_position = get_collision_point().snapped(snapping)
		elif uneditable_ray_cast.is_colliding():
			remote_transform.global_position = uneditable_ray_cast.get_collision_point().snapped(snapping)

	# Changed targets
	if looking_at != get_collider():
		
		# Reset the previous target
		if looking_at:
			hide_outline(looking_at)
			# Show the outline for the new target
			if get_collider() != null:
				show_outline(get_collider())
		# Previous target was nothing
		else:
			show_outline(get_collider())
			
		looking_at = get_collider()

func set_material_overlay_for_children(node: Node3D, material: StandardMaterial3D, _transparency : float):
	for child in node.get_children():
		if child is MeshInstance3D:
			child.material_overlay = material
			#child.transparency = transparency
		if child is Node3D:
			set_material_overlay_for_children(child, material, _transparency)

func show_outline(node: Node3D):
	set_material_overlay_for_children(node.owner, outline_material, 0.2)

func hide_outline(node: Node3D):
	set_material_overlay_for_children(node.owner, null, 0.0)
