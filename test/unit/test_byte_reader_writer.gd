extends GutTest

var ByteReaderClass = load("res://Scripts/Networking/ByteReader.gd")
var ByteWriterClass = load("res://Scripts/Networking/ByteWriter.gd")

var _reader : ByteReader
var _writer : ByteWriter

func before_each():
	_writer = ByteWriterClass.new()
	_reader = ByteReaderClass.new(_writer.data)
	#_reader.data = _writer.data

func test_can_read_write_vector3():
	var ev = Vector3(1.0, 2.0, 3.0)
	_writer.write_vector3(ev)
	assert_eq(_writer.offset, 6, "Incorrect offset after writing Vector3")
	
	var read_value = _reader.read_vector3()
	assert_eq(read_value, ev, "Didn't read the value back correctly")

func test_can_read_write_int():
	var ev = 9001
	_writer.write_int(ev)
	assert_eq(_writer.offset, 2, "Incorrect offset after writing int")
	
	var read_value = _reader.read_int()
	assert_eq(read_value, ev, "Didn't read the value back correctly")

func test_can_read_write_small_float():
	var ev = 0.5
	_writer.write_small_float(ev)
	assert_eq(_writer.offset, 2, "Incorrect offset after writing float")
	
	var read_value = _reader.read_small_float()
	assert_eq(read_value, ev, "Didn't read the value back correctly")

var rounded_float_cases = [
	[0.2, 0.01, 0.2],
	[0.02, 0.01, 0.02],
	[0.01996, 0.01, 0.02],
]

func test_can_read_write_small_float_rounded(params=use_parameters(rounded_float_cases)):
	var write_value = params[0]
	var round_amount = params[1]
	var ev = params[2]
	_writer.write_small_float(write_value)
	assert_eq(_writer.offset, 2, "Incorrect offset after writing float")
	
	var read_value = _reader.read_small_float(round_amount)
	assert_eq(read_value, ev, "Didn't read the value back correctly")

func test_can_read_write_float():
	var ev = 10000000.05
	_writer.write_float(ev)
	assert_eq(_writer.offset, 4, "Incorrect offset after writing float")
	
	var read_value = _reader.read_float()
	assert_almost_eq(read_value, ev, 1.0, "Didn't read the value back correctly")

func test_can_read_write_big_int():
	var ev = 2147483647
	_writer.write_big_int(ev)
	assert_eq(_writer.offset, 8, "Incorrect offset after writing float")
	
	var read_value = _reader.read_big_int()
	assert_eq(read_value, ev, "Didn't read the value back correctly")

func test_can_read_write_path():
	var some_node = Node3D.new()
	add_child_autoqfree(some_node)
	
	_writer.write_path_to(some_node)
	
	var read_value = _reader.read_path_to()
	assert_eq(get_node(read_value), some_node)

func test_can_read_write_str():
	var ev = "Testy"
	
	_writer.write_str(ev)
	
	var read_value = _reader.read_str()
	assert_eq(read_value, ev)

func test_can_read_write_int_array():
	var ev : Array[int] = [2, 1, 1, 2, 5, 6, 50, 1000, 2000]
	
	_writer.write_int_array(ev)
	
	var read_value : Array[int] = _reader.read_int_array()
	assert_eq_deep(read_value, ev)

func test_can_read_write_color():
	var ev : Color = Color.FOREST_GREEN
	
	_writer.write_color(ev)
	
	var read_value = _reader.read_color()
	assert_almost_eq(read_value.r, ev.r, 0.02)
	assert_almost_eq(read_value.g, ev.g, 0.02)
	assert_almost_eq(read_value.b, ev.b, 0.02)
	assert_almost_eq(read_value.a, ev.a, 0.02)

func test_can_read_write_vec3_dictionary():
	var ev: Dictionary = {
		"global_position": Vector3(1.05, 2.2, 3.7777),
		"global_rotation": Vector3(1.0001, 2.022, 3.01),
		"global_scale": Vector3(1.1111, 2.77, 3.06),
	}

	_writer.write_vec3_dict(ev)

	var read_value = _reader.read_vec3_dict()
	assert_eq(ev.size(), read_value.size())
	for property in ev:
		assert_almost_eq(read_value[property], ev[property], Vector3(0.1, 0.1, 0.1))
