extends Node3D
class_name PatienceBar

@onready var bar : Sprite3D = $BarPivot/Bar
@onready var icon : Sprite3D = $Icon
@onready var bar_pivot : Node3D = $BarPivot

var patience_gradient : Gradient = load("res://Resources/gradients/patience_gradient.tres")

func reset():
	bar_pivot.scale.y = 1.0
	bar.modulate = patience_gradient.sample(0.0)

func show_visual():
	reset()
	show()

func hide_visual():
	hide()
	reset()

func _on_patience_changed(patience: float):
	var clamped_patience = clamp(patience, 0, 1.0)
	bar_pivot.scale.y = clamped_patience
	bar.modulate = patience_gradient.sample(1.0 - clamped_patience)
