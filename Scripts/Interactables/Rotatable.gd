extends Interactable
class_name Rotatable

signal rotated

## Set in degrees, but converted to radians on _ready for the Tween
@export var tar_rot = Vector3(0.0, -90.0, 0.0)
@export var time_to_rotate_seconds = 0.3
@export var is_rotated = false
@export var rotate_sfx : AudioStream

@onready var audio_player : AudioStreamPlayer3D = $AudioStreamPlayer3D

var og_rot : Vector3
var in_progress = false

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	is_rotated = reader.read_bool()
	in_progress = reader.read_bool()
	
	if is_rotated or in_progress:
		get_parent().rotation = tar_rot

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	writer.write_bool(is_rotated)
	writer.write_bool(in_progress)
	return writer

func _ready():
	super()
	audio_player.stream = rotate_sfx
	og_rot = get_parent().rotation
	tar_rot.x = deg_to_rad(tar_rot.x)
	tar_rot.y = deg_to_rad(tar_rot.y)
	tar_rot.z = deg_to_rad(tar_rot.z)
	
func _interact(_player: Player):
	rotate_parent()

func _secondary_interact(player: Player):
	interact(player)

func rotate_parent():
	if in_progress:
		return
	in_progress = true
	audio_player.play()

	var t = create_tween()
	if is_rotated:
		t.tween_property(get_parent(), "rotation", og_rot, time_to_rotate_seconds).set_ease(Tween.EASE_IN)
	else:
		t.tween_property(get_parent(), "rotation", tar_rot, time_to_rotate_seconds).set_ease(Tween.EASE_OUT)

	await t.finished
	in_progress = false
	is_rotated = !is_rotated
	rotated.emit()

## Setup method, if any scenes need the rotatable to be in a particular state without emitting signals
## Use this to get it there
func force_rotate_parent() -> void:
	if is_rotated:
		get_parent().rotation = og_rot
	else:
		get_parent().rotation = tar_rot
	is_rotated = !is_rotated
	in_progress = false

