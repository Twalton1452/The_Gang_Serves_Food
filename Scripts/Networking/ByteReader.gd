class_name ByteReader

var data = PackedByteArray()
var offset = 0

func _init(to_read: PackedByteArray):
	data = to_read

func decode_half() -> float:
	var decoded = data.decode_half(offset)
	offset += 2
	return decoded

func decode_u8() -> int:
	var decoded = data.decode_u8(offset)
	offset += 1
	return decoded

func decode_u16() -> int:
	var decoded = data.decode_u16(offset)
	offset += 2
	return decoded

func decode_u32() -> int:
	var decoded = data.decode_u32(offset)
	offset += 4
	return decoded

func decode_utf8_str() -> String:
	var str_size = decode_u8()
	var utf8_str = data.slice(offset, offset + str_size).get_string_from_utf8()
	offset += str_size
	return utf8_str

func read_str() -> String:
	return decode_utf8_str()

func read_path_to() -> String:
	return decode_utf8_str()

func read_vector3() -> Vector3:
	return Vector3(decode_half(), decode_half(), decode_half())

func read_bool() -> bool:
	return bool(decode_u8())

func read_float() -> float:
	return decode_half()

func read_int() -> int:
	return decode_u16()
