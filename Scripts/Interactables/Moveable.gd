extends Interactable
class_name Moveable

signal moved

@export var move_amount = Vector3(0.0, -1.0, 0.0)

var is_moved = false
var original_position : Vector3
var in_progress = false

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	is_moved = reader.read_bool()
	in_progress = reader.read_bool()
	original_position = reader.read_vector3()
	
	if is_moved or in_progress:
		get_parent().position = original_position + move_amount
	else:
		get_parent().position = original_position

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	writer.write_bool(is_moved)
	writer.write_bool(in_progress)
	writer.write_vector3(original_position)
	return writer

func _ready():
	super()
	original_position = get_parent().position
	
func _interact(_player: Player):
	move_parent()

func _secondary_interact(player: Player):
	interact(player)

func move_parent():
	if in_progress:
		return
	in_progress = true

	var tween = create_tween()
	if is_moved:
		tween.tween_property(get_parent(), "position", original_position, 0.3).set_ease(Tween.EASE_IN)
	else:
		tween.tween_property(get_parent(), "position", original_position + move_amount, 0.3).set_ease(Tween.EASE_OUT)

	await tween.finished
	in_progress = false
	is_moved = !is_moved
	moved.emit()
