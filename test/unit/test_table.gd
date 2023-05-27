extends GutTest

var TableClass = load("res://Scripts/Restaurant/Table.gd")

var _table : Table = null
var _chair : Node3D = null

func before_each():
	_table = partial_double(TableClass, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	_chair = Node3D.new()
	add_child_autoqfree(_table)
	_table.add_child(_chair)
	_table.chairs.push_back(_chair)
	watch_signals(_table)

func test_can_sit_at_available_table():
	var customer = Node3D.new()
	add_child_autofree(customer)
	assert_eq(_table.is_empty, true, "Table isn't empty")
	_table.seat_customer(customer)
	assert_eq(_table.is_empty, false, "Table is empty")
	assert_signal_emitted(_table, "occupied", "occupied signal never emitted")
	# Something is not occupying the chairs
	# Signal is emitted that table is no longer available once something sits

func test_can_leave_table():
	pass
	# Something is sitting at the table
	# Signal is emitted that table is available after leaving
