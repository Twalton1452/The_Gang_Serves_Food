extends Node3D
class_name WorldProgressBar

@export var smooth = true
@export var icon_texture : CompressedTexture2D : set = set_icon_texture

@onready var pivot : Node3D = $Pivot
@onready var bar : Sprite3D = $Pivot/BarPivot/Bar
@onready var icon : Sprite3D = $Pivot/Icon
@onready var bar_pivot : Node3D = $Pivot/BarPivot

var progress_gradient : Gradient = load("res://Resources/gradients/progress_gradient.tres")
var progress_bar_tween : Tween = null
var reset_tween : Tween = null
var time_between_ticks = 0.1

func set_icon_texture(value: CompressedTexture2D) -> void:
	icon_texture = value
	if not is_node_ready():
		await ready
	icon.texture = icon_texture

func reset(progress = 0.0):
	if progress_bar_tween != null and progress_bar_tween.is_valid():
		progress_bar_tween.kill()
	bar_pivot.scale.x = progress
	bar.modulate = progress_gradient.sample(progress)

func pop():
	if reset_tween != null and reset_tween.is_valid():
		reset_tween.kill()
		bar_pivot.scale = Vector3.ONE
	reset_tween = create_tween()
	reset_tween.tween_property(pivot, "scale", Vector3.ONE * 1.2, 0.2).set_trans(Tween.TRANS_ELASTIC)
	reset_tween.tween_property(pivot, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT)

func show_visual(progress = 0.0):
	reset(progress)
	show()
	pop()

func hide_visual():
	hide()
	reset()

func _on_progress_changed(progress: float):
	var clamped_progress = clamp(progress, 0, 1.0)
	var color = progress_gradient.sample(clamped_progress)
	
	# Positive progress can move smoothly, but negative should snap
	if smooth and clamped_progress > bar_pivot.scale.x:
		smooth_change(clamped_progress, color)
	else:
		unsmooth_change(clamped_progress, color)

func smooth_change(progress: float, color: Color):
	if progress >= 1.0:
		if progress_bar_tween != null and progress_bar_tween.is_valid():
			progress_bar_tween.kill()
		bar_pivot.scale.x = 1.0
	else:
		progress_bar_tween = create_tween()
		progress_bar_tween.tween_property(bar_pivot, "scale:x", progress, time_between_ticks).set_ease(progress_bar_tween.EASE_OUT)
	bar.modulate = color

func unsmooth_change(progress:float, color: Color) -> void:
	bar_pivot.scale.x = progress
	bar.modulate = color

func update(progress: float) -> void:
	_on_progress_changed(progress)
