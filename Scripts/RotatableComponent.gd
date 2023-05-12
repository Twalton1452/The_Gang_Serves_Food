extends NetworkedNode3D
class_name RotatableComponent

## Set in degrees, but converted to radians on _ready for the Tween
@export var tar_rot = Vector3(0.0, -90.0, 0.0)
@export var is_rotated = false

var og_rot : Vector3

var in_progress = false

func set_sync_state(value) -> int:
	var continuing_offset = super(value)
	is_rotated = bool(value.decode_u8(continuing_offset))
	in_progress = bool(value.decode_u8(continuing_offset + 1))
	
	print("yep")
	if is_rotated or in_progress:
		get_parent().rotation = tar_rot
	
	return continuing_offset + 2

func get_sync_state() -> PackedByteArray:
	var buf = super()
	var end_of_parent_buf = buf.size()
	buf.resize(end_of_parent_buf + 2)
	buf.encode_u8(end_of_parent_buf, is_rotated) # u8 is 1 byte
	buf.encode_u8(end_of_parent_buf + 1, in_progress) # u8 is 1 byte
	return buf

func _ready():
	super()
	og_rot = get_parent().rotation
	tar_rot.x = deg_to_rad(tar_rot.x)
	tar_rot.y = deg_to_rad(tar_rot.y)
	tar_rot.z = deg_to_rad(tar_rot.z)

func _on_interactable_component_interacted(node, _player):
	rotate_parent(node)

func rotate_parent(node):
	if in_progress:
		return
	in_progress = true

	var t = create_tween()
	if is_rotated:
		t.tween_property(node.get_parent(), "rotation", og_rot, 0.3).set_ease(Tween.EASE_IN)
	else:
		t.tween_property(node.get_parent(), "rotation", tar_rot, 0.3).set_ease(Tween.EASE_OUT)

	await t.finished
	in_progress = false
	is_rotated = !is_rotated

