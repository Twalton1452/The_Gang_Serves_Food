extends AIBody
class_name Customer

var sitting_chair : Chair = null

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	(get_parent() as CustomerParty).sync_customer(self)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	return super(writer)
