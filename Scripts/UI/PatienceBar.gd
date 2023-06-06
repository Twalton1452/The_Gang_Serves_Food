extends Node3D
class_name PatienceBar

@export var smooth = true

@onready var bar : Sprite3D = $BarPivot/Bar
@onready var icon : Sprite3D = $Icon
@onready var bar_pivot : Node3D = $BarPivot

var patience_gradient : Gradient = load("res://Resources/gradients/patience_gradient.tres")
var progress_bar_tween : Tween = null
var reset_tween : Tween = null

func reset():
	if progress_bar_tween != null and progress_bar_tween.is_valid():
		progress_bar_tween.kill()
	bar_pivot.scale.y = 1.0
	bar.modulate = patience_gradient.sample(0.0)

func pop():
	if reset_tween != null and reset_tween.is_valid():
		reset_tween.kill()
		bar_pivot.scale = Vector3.ONE
	reset_tween = create_tween()
	reset_tween.tween_property(self, "scale", Vector3.ONE * 1.2, 0.2).set_trans(Tween.TRANS_ELASTIC)
	reset_tween.tween_property(self, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT)

func show_visual():
	reset()
	show()
	pop()

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
	if patience < bar_pivot.scale.y and patience > 0:
		progress_bar_tween = create_tween()
		progress_bar_tween.tween_property(bar_pivot, "scale:y", patience, NetworkedPartyManager.patience_tick_rate_seconds).set_ease(progress_bar_tween.EASE_OUT)
	elif progress_bar_tween != null and progress_bar_tween.is_valid():
		progress_bar_tween.kill()
		bar_pivot.scale.y = 0.0
	bar.modulate = color
