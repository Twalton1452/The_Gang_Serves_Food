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

func test_can_read_write_float():
	var ev = 0.5
	_writer.write_float(ev)
	assert_eq(_writer.offset, 2, "Incorrect offset after writing float")
	
	var read_value = _reader.read_float()
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
