extends AIBody
class_name Customer

var sitting_chair : Chair = null

func set_sync_state(reader: ByteReader) -> void:
	super(reader)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	return super(writer)
