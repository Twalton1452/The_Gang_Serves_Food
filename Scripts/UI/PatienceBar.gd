extends Node3D
class_name PatienceBar

@export var smooth = true
@export_category("Movement")
@export var move_during_progress = true
@export var move_to = Vector3(0.0, 0.8, 0.0)

@onready var pivot : Node3D = $Pivot
@onready var bar : Sprite3D = $Pivot/BarPivot/Bar
@onready var icon : Sprite3D = $Pivot/Icon
@onready var bar_pivot : Node3D = $Pivot/BarPivot

var patience_gradient : Gradient = load("res://Resources/gradients/patience_gradient.tres")
var progress_bar_tween : Tween = null
var reset_tween : Tween = null
var move_to_tween : Tween = null

func reset(patience = 1.0):
	if move_to_tween != null and move_to_tween.is_valid():
		move_to_tween.kill()
	pivot.position = Vector3.ZERO
	
	if progress_bar_tween != null and progress_bar_tween.is_valid():
		progress_bar_tween.kill()
	bar_pivot.scale.y = patience
	bar.modulate = patience_gradient.sample(1.0 - patience)

func pop():
	if reset_tween != null and reset_tween.is_valid():
		reset_tween.kill()
		bar_pivot.scale = Vector3.ONE
	reset_tween = create_tween()
	reset_tween.tween_property(pivot, "scale", Vector3.ONE * 1.2, 0.2).set_trans(Tween.TRANS_ELASTIC)
	reset_tween.tween_property(pivot, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT)

func show_visual(patience = 1.0):
	reset(patience)
	show()
	pop()

func hide_visual():
	hide()
	reset()

func _on_patience_changed(patience: float):
	var clamped_patience = clamp(patience, 0, 1.0)
	var color = patience_gradient.sample(1.0 - clamped_patience)
	
	if move_during_progress:
		move(clamped_patience)
	
	if smooth:
		smooth_change(clamped_patience, color)
	else:
		unsmooth_change(clamped_patience, color)

func move(patience: float) -> void:
	var progress_to_destination = pow(1.0 - patience, 2)
	if progress_to_destination > 0.64: # rise to the top, lost 80% patience
		progress_to_destination = 1.0
	elif progress_to_destination < 0.06: # start rising after 25% patience
		progress_to_destination = 0.0
		
	var next_position = Vector3.ZERO.lerp(move_to, progress_to_destination)
	move_to_tween = create_tween()
	move_to_tween.tween_property(pivot, "position", next_position, NetworkedPartyManager.patience_tick_rate_seconds).set_ease(progress_bar_tween.EASE_OUT)

func smooth_change(patience: float, color: Color):
	if patience < bar_pivot.scale.y and patience > 0:
		progress_bar_tween = create_tween()
		progress_bar_tween.tween_property(bar_pivot, "scale:y", patience, NetworkedPartyManager.patience_tick_rate_seconds).set_ease(progress_bar_tween.EASE_OUT)
	elif progress_bar_tween != null and progress_bar_tween.is_valid():
		progress_bar_tween.kill()
		bar_pivot.scale.y = 0.0
	bar.modulate = color

func unsmooth_change(patience:float, color: Color) -> void:
	bar_pivot.scale.y = patience
	bar.modulate = color
