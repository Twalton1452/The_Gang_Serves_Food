extends Area3D
class_name InteractableComponent

# Maybe rename these to: Pickup / (Combine/Interact)
signal interacted(node : InteractableComponent, player : Player)
signal secondary_interacted(node : InteractableComponent, player : Player)

func interact(player : Player, secondary = false):
	if not secondary:
		interacted.emit(self, player)
	else:
		secondary_interacted.emit(self, player)
