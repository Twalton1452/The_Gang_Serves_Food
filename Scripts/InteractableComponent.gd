extends Area3D
class_name InteractableComponent

signal interacted(node)

func interact():
	interacted.emit(self)
