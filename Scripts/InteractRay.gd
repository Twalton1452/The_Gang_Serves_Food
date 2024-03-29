extends RayCast3D

@export var highlight_enabled = true

var outline_material : StandardMaterial3D = preload("res://Materials/Grow_Outline_mat.tres")
var looking_at : Interactable = null
#var current_material : BaseMaterial3D = null

func _unhandled_input(event):
	if event.is_action_pressed("ui_right"):
		highlight_enabled = !highlight_enabled
		if looking_at:
			hide_outline(looking_at)

func _physics_process(_delta):
	if not highlight_enabled:
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

func show_outline(interactable: Interactable):
	if interactable.mesh_to_highlight != null:
		interactable.mesh_to_highlight.material_overlay = outline_material
		
#		current_material = interactable.mesh_to_highlight.get_active_material(0)
#		interactable.mesh_to_highlight.set_surface_override_material(0, outline_material)
#		interactable.mesh_to_highlight.material_override = outline_material

func hide_outline(interactable: Interactable):
	if interactable.mesh_to_highlight != null:
		interactable.mesh_to_highlight.material_overlay = null
#		interactable.mesh_to_highlight.set_surface_override_material(0, current_material)

#	current_material = null
