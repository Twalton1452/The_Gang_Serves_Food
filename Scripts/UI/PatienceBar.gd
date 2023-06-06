extends Node3D
class_name PatienceBar

@export var smooth = true

@onready var bar : Sprite3D = $BarPivot/Bar
@onready var icon : Sprite3D = $Icon
@onready var bar_pivot : Node3D = $BarPivot

var patience_gradient : Gradient = load("res://Resources/gradients/patience_gradient.tres")
var tween : Tween = null

func reset():
	if tween != null and tween.is_valid():
		tween.kill()
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
	var color = patience_gradient.sample(1.0 - clamped_patience)
	
	if smooth:
		smooth_change(clamped_patience, color)
	else:
		bar_pivot.scale.y = clamped_patience
		bar.modulate = color

func smooth_change(patience: float, color: Color):
	if patience < bar_pivot.scale.y and patience >= 0:
		tween = create_tween()
		tween.tween_property(bar_pivot, "scale:y", patience, NetworkedPartyManager.patience_tick_rate_seconds).set_ease(Tween.EASE_OUT)
		tween.tween_property(bar, "modulate", color, NetworkedPartyManager.patience_tick_rate_seconds)
	else:
		bar_pivot.scale.y = patience
		bar.modulate = color
