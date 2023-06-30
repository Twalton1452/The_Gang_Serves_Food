extends Resource
class_name GameModifiers

func set_sync_state(reader: ByteReader):
	dirt_spawn_after_eating = reader.read_bool()

func get_sync_state() -> ByteWriter:
	var writer : ByteWriter = ByteWriter.new()
	writer.write_bool(dirt_spawn_after_eating)
	return writer

@export var dirt_spawn_after_eating = false
