extends RayCast3D

var looking_at : InteractableComponent = null

func _physics_process(_delta):
	
	if looking_at != get_collider():
		
		if looking_at:
			looking_at.hide_outline()
			if get_collider() != null:
				get_collider().show_outline()
			print("hide current")
		else:
			get_collider().show_outline()
			print("show")
			
		looking_at = get_collider()
