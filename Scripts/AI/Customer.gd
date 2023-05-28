extends AIBody
class_name Customer

var sitting_chair : Chair = null

func set_sync_state(value: PackedByteArray) -> void:
	super(value)

func get_sync_state() -> PackedByteArray:
	return super()
