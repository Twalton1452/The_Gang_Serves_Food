extends RayCast3D

@onready var remote_transform : RemoteTransform3D = $RemoteTransform3D
@onready var uneditable_ray_cast : RayCast3D = $UneditableRayCast3D

var outline_material : StandardMaterial3D = preload("res://Materials/Grow_Outline_mat.tres")
var looking_at : Node3D = null

func enable():
	enabled = true
	uneditable_ray_cast.enabled = true

func disable():
	enabled = false
	uneditable_ray_cast.enabled = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_left"):
		enabled = !enabled
		if looking_at:
			hide_outline(looking_at)

func _physics_process(_delta):
	if not enabled:
		return
	if remote_transform.remote_path != null:
		if is_colliding():
			remote_transform.global_position.y = get_collider().global_position.y
		elif uneditable_ray_cast.is_colliding():
			remote_transform.global_position.y = uneditable_ray_cast.get_collider().global_position.y
		else:
			remote_transform.position.y = 0.0
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

func set_material_overlay_for_children(node: Node3D, material: StandardMaterial3D, transparency : float):
	for child in node.get_children():
		if child is MeshInstance3D:
			child.material_overlay = material
			child.transparency = transparency
		if child is Node3D:
			set_material_overlay_for_children(child, material, transparency)

func show_outline(node: Node3D):
	set_material_overlay_for_children(node.owner, outline_material, 0.2)

func hide_outline(node: Node3D):
	set_material_overlay_for_children(node.owner, null, 0.0)
