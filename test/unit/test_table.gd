extends GutTest

var TableClass = load("res://Scripts/Restaurant/Table.gd")
var ChairClass = load("res://Scripts/Restaurant/Chair.gd")

var _table : Table = null
var _chairs : Array[Chair] = []

func before_each():
	_table = partial_double(TableClass, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	add_child_autoqfree(_table)
	watch_signals(_table)
	
	for i in range(4):
		var chair = ChairClass.new()
		_chairs.push_back(chair)
		chair.position = Vector3(1.0 + i, 0.0, 1.0) # this is a very weird table
		_table.add_child(chair)
		var behind_chair = Node3D.new()
		chair.add_child(behind_chair)
		chair.transition_location = behind_chair
		behind_chair.position = Vector3.BACK
	
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

func test_customers_can_sit_at_available_table_and_get_up(params=use_parameters(customer_params)):
	var customers : Array[Node3D] = []
	for param in params:
		customers.push_back(add_child_autofree(param.new()))
		assert_eq(customers[-1].position, Vector3.ZERO, "Customer isn't starting at 0,0,0")
	
	assert_eq(_table.is_empty, true, "Table isn't empty")
	
	_table.seat_customers(customers)
	
	assert_eq(_table.is_empty, false, "Table is empty")
	assert_signal_emitted(_table, "occupied", "occupied signal never emitted")
	
	for customer in customers:
		var in_one_of_the_chairs = false
		for chair in _chairs:
			if customer.position == chair.position:
				assert_eq(chair.sitter, customer, "A customer has my chair position but is in a different seat")
				in_one_of_the_chairs = true
				break
		assert_eq(in_one_of_the_chairs, true, "A customer isn't sitting in a chair")
	
	_table.release_customers()
	
	assert_eq(_table.is_empty, true, "Table isn't empty")
	assert_signal_emitted(_table, "available", "available signal never emitted")
	
	for customer in customers:
		var is_behind_the_chair = false
		for chair in _chairs:
			assert_eq(chair.sitter, null, "A customer is still in my chair despite being forced out")
			if customer.position == chair.transition_location.position:
				is_behind_the_chair = true
				break
		assert_eq(is_behind_the_chair, true, "A customer isn't in the transition location")
	
