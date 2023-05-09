extends Area3D
class_name InteractableComponent

signal interacted(node : InteractableComponent, player : Player)

func interact(player):
	interacted.emit(self, player)
