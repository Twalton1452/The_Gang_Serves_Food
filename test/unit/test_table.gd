extends GutTest

var TableClass = load("res://Scripts/Restaurant/Table.gd")
var ChairClass = load("res://Scripts/Restaurant/Chair.gd")
var HolderClass = load("res://Scripts/Holder.gd")

var _table : Table = null
var _chairs : Array[Chair] = []

func before_each():
	_table = partial_double(TableClass, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	stub(_table, "set_color").to_do_nothing()
	add_child_autoqfree(_table)
	watch_signals(_table)
	
	for i in range(4):
		var chair = ChairClass.new()
		_chairs.push_back(chair)
		chair.position = Vector3(1.0 + i, 0.0, 1.0) # this is a very weird table
		var holder = Holder.new()
		_table.add_child(chair)
		_table.add_child(holder)
		var chair_sit_loc = Node3D.new()
		var behind_chair_loc = Node3D.new()
		chair.add_child(chair_sit_loc)
		chair.add_child(behind_chair_loc)
		chair.holder = holder
		chair.sitting_location = chair_sit_loc
		chair.transition_location = behind_chair_loc
		chair_sit_loc.position = Vector3(0.0, 0.0, 0.5)
		behind_chair_loc.position = Vector3.BACK
	
	_table.chairs = _chairs

func after_each():
	# Clear the chairs array otherwise there will be <Freed Object>'s inside the array
	# when tests are ran with use_parameters()
	_table.chairs.clear()

var customer_params = [
	[Node3D],
	[Node3D,Node3D],
	[Node3D,Node3D,Node3D],
	[Node3D,Node3D,Node3D,Node3D],
]

func test_partys_can_sit_at_available_table_and_get_up(params=use_parameters(customer_params)):
	# Arrange
	var bodies : Array[Node3D] = []
	for param in params:
		bodies.push_back(add_child_autofree(param.new()))
		assert_eq(bodies[-1].position, Vector3.ZERO, "Node3D isn't starting at 0,0,0")
	
	assert_eq(_table.is_empty, true, "Table isn't empty")
	
	# Act
	_table.seat_customers(bodies)
	
	# Assert
	assert_eq(_table.is_empty, false, "Table is empty")
	assert_signal_emitted(_table, "occupied", "occupied signal never emitted")
	for body in bodies:
		var in_one_of_the_chairs = false
		for chair in _chairs:
			if body.global_position.is_equal_approx(chair.sitting_location.global_position):
				assert_eq(chair.sitter, body, "A body has my chair position but is in a different seat")
				in_one_of_the_chairs = true
				break
		assert_eq(in_one_of_the_chairs, true, "A body isn't sitting in a chair")
	
	# Act
	_table.release_customers()
	
	# Assert
	assert_eq(_table.is_empty, true, "Table isn't empty")
	assert_signal_emitted(_table, "available", "available signal never emitted")
	for body in bodies:
		var is_behind_the_chair = false
		for chair in _chairs:
			assert_eq(chair.sitter, null, "A body is still in my chair despite being forced out")
			if body.global_position.is_equal_approx(chair.transition_location.global_position):
				is_behind_the_chair = true
				break
		assert_eq(is_behind_the_chair, true, "A body isn't in the transition location")

var unavail_params = [
	[Node3D],
	[Node3D,Node3D],
	[Node3D,Node3D,Node3D],
	[Node3D,Node3D,Node3D,Node3D],
]

func test_partys_can_not_sit_at_unavailable_table(params=use_parameters(unavail_params)):
	# Arrange
	var seated_customer = add_child_autoqfree(Node3D.new())
	_table.seat_customers([seated_customer])
	
	var bodies : Array[Node3D] = []
	for param in params:
		bodies.push_back(add_child_autofree(param.new()))
		assert_eq(bodies[-1].position, Vector3.ZERO, "Node3D isn't starting at 0,0,0")
	
	assert_eq(_table.is_empty, false, "Table isn't empty")
	
	# Act
	_table.seat_customers(bodies)
	
	# Assert
	var is_already_seated_customer_or_null = true
	for chair in _table.chairs:
		if chair.sitter == null or chair.sitter == seated_customer:
			continue
		is_already_seated_customer_or_null = false
		break
	assert_eq(is_already_seated_customer_or_null, true, "The party sat at an unavailable table")
			

