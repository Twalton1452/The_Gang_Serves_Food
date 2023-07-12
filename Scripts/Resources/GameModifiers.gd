extends Resource
class_name GameModifiers

func set_sync_state(reader: ByteReader):
	dirt_spawn_after_eating = reader.read_bool()
	min_party_size = reader.read_int()
	max_party_size = reader.read_int()

func get_sync_state(writer: ByteWriter) -> void:
	writer.write_bool(dirt_spawn_after_eating)
	writer.write_int(min_party_size)
	writer.write_int(max_party_size)

@export var dirt_spawn_after_eating = false
@export var min_party_size = 4
@export var max_party_size = 4
