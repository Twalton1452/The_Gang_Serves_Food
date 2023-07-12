class_name ByteReader

const FLOAT_SIGNIFICANT_DIGITS = 0.001

var data = PackedByteArray()
var offset = 0

func _init(to_read: PackedByteArray):
	data = to_read

func decode_half() -> float:
	var decoded = data.decode_half(offset)
	offset += 2
	return snapped(decoded, FLOAT_SIGNIFICANT_DIGITS)

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

func decode_u64() -> int:
	var decoded = data.decode_u64(offset)
	offset += 8
	return decoded
	
func decode_float() -> float:
	var decoded = data.decode_float(offset)
	offset += 4
	return snapped(decoded, FLOAT_SIGNIFICANT_DIGITS)

func decode_utf8_str() -> String:
	var str_size = decode_u8()
	var utf8_str = data.slice(offset, offset + str_size).get_string_from_utf8()
	offset += str_size
	return utf8_str

func read_str() -> String:
	return decode_utf8_str()

func read_path_to() -> String:
	return decode_utf8_str()

func read_relative_path_to() -> String:
	return decode_utf8_str()

func read_vector3() -> Vector3:
	return Vector3(decode_half(), decode_half(), decode_half())

func read_color() -> Color:
	return Color(decode_half(),decode_half(),decode_half(),decode_half())

## Format { "str": Vector3() }
func read_vec3_dict() -> Dictionary:
	var num_keys = decode_u8()
	var dict = {}
	for _key in range(num_keys):
		var property = read_str()
		var vec3 = read_vector3()
		dict[property] = vec3
	return dict

## Max length of 256, Max values inside 65535
func read_int_array() -> Array[int]:
	var size = decode_u8()
	var decoded_arr : Array[int] = []
	var starting_offset = offset
	while offset < starting_offset + size:
		decoded_arr.push_back(read_int())
	return decoded_arr

func read_bool() -> bool:
	return bool(decode_u8())

## Max value 256
## round_to_decimal included as this is primarily used for percentages
## 0.2 values over the network would get distorted to 0.19996
## this could cause a desync
func read_small_float(round_to_decimal: float = 0.01) -> float:
	return snapped(decode_half(), round_to_decimal)

func read_float() -> float:
	return decode_float()

func read_int() -> int:
	return decode_u16()

func read_big_int() -> int:
	return decode_u64()
