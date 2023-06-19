extends RayCast3D

var outline_material : StandardMaterial3D = preload("res://Materials/Grow_Outline_mat.tres")
var looking_at : Node3D = null

func _unhandled_input(event):
	if event.is_action_pressed("ui_left"):
		enabled = !enabled
		if looking_at:
			hide_outline(looking_at)

func _physics_process(_delta):
	if not enabled:
		return
	
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

func set_material_overlay_for_children(node: Node3D, material: StandardMaterial3D):
	for child in node.get_children():
		if child is MeshInstance3D:
			child.material_overlay = material
		if child is Node3D:
			set_material_overlay_for_children(child, material)

func show_outline(node: Node3D):
	set_material_overlay_for_children(node.owner, outline_material)

func hide_outline(node: Node3D):
	set_material_overlay_for_children(node.owner, null)
