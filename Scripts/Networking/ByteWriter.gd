class_name ByteWriter

var data = PackedByteArray()
var offset = 0

func encode_half(value: float) -> void:
	offset += 2
	data.resize(offset)
	data.encode_half(offset - 2, value)

func encode_u8(value: int) -> void:
	offset += 1
	data.resize(offset)
	data.encode_u8(offset - 1, value)

func encode_u16(value: int) -> void:
	offset += 2
	data.resize(offset)
	data.encode_u16(offset - 2, value)

func encode_u32(value: int) -> void:
	offset += 4
	data.resize(offset)
	data.encode_u32(offset - 4, value)

func append_array(arr: PackedByteArray) -> void:
	offset += arr.size()
	data.append_array(arr)

## Max value 256,256,256
func write_vector3(vec3: Vector3):
	encode_half(vec3.x) 
	encode_half(vec3.y)
	encode_half(vec3.z)

## Max length of 256, Max values inside 65535
func write_int_array(arr: Array[int]) -> void:
	encode_u8(arr.size() * 2) # 2 for each byte from u16
	for num in arr:
		write_int(num)

func write_path_to(node: Node) -> void:
	var path_to = StringName(node.get_path()).to_utf8_buffer()
	encode_u8(path_to.size())
	append_array(path_to)
	
func write_str(s: String):
	var s_buf = StringName(s).to_utf8_buffer()
	encode_u8(s_buf.size())
	append_array(s_buf)

## Max value 256
func write_float(v: float):
	encode_half(v)

func write_bool(b: bool):
	encode_u8(b)

## Max value 65535
func write_int(v: int):
	encode_u16(v)
