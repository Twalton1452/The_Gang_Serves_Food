extends RayCast3D

var outline_material : ShaderMaterial = preload("res://Materials/outline_material.tres")
var current_material : BaseMaterial3D = null
var looking_at : Interactable = null

func _physics_process(_delta):
	
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
		current_material = interactable.mesh_to_highlight.material_override
		interactable.mesh_to_highlight.material_override = outline_material

func hide_outline(interactable: Interactable):
	if interactable.mesh_to_highlight != null:
		interactable.mesh_to_highlight.material_override = current_material
	current_material = null
