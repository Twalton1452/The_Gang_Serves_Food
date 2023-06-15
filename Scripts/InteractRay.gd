extends RayCast3D

@export var highlight_enabled = true

#var outline_material : ShaderMaterial = preload("res://Materials/outline_material.tres")
var outline_material : StandardMaterial3D = preload("res://Materials/Outline_mat.tres")
var current_material : BaseMaterial3D = null
var looking_at : Interactable = null

func _unhandled_input(event):
	if event.is_action_pressed("ui_end"):
		highlight_enabled = !highlight_enabled

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
		current_material = interactable.mesh_to_highlight.get_active_material(0)
		current_material.next_pass = outline_material
		#interactable.mesh_to_highlight.material_override = outline_material

func hide_outline(interactable: Interactable):
	if interactable.mesh_to_highlight != null:
		#interactable.mesh_to_highlight.material_override = current_material
		current_material.next_pass = null
	current_material = null
