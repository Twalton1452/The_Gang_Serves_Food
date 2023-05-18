extends Area3D
class_name InteractableComponent

# Maybe rename these to: Pickup / (Combine/Interact)
signal interacted(node : InteractableComponent, player : Player)
signal secondary_interacted(node : InteractableComponent, player : Player)

func interact(_player : Player):
	pass

func secondary_interact(_player : Player):
	pass
