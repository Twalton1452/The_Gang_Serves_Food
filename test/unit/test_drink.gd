extends GutTest

var _drink : Drink = null
var _drink_fountain_power = 0.1

func before_each():
	_drink = Drink.new()
	add_child_autoqfree(_drink)
	_drink.empty_threshold = 0.2
	_drink.partial_fill_threshold = 0.7
	_drink.filled_threshold = 1.0

func test_drink_can_set_fill_state():
	# kind of hideous, but deterministic
	# this test file won't be doing much anyway
	assert_eq(_drink.fill_amount, 0.0)
	assert_eq(_drink.fill_state, Drink.FillState.EMPTY)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.EMPTY)
	assert_almost_eq(_drink.fill_amount, 0.1, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.2, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.3, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.4, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.5, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.6, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.FILLED)
	assert_almost_eq(_drink.fill_amount, 0.7, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.FILLED)
	assert_almost_eq(_drink.fill_amount, 0.8, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.FILLED)
	assert_almost_eq(_drink.fill_amount, 0.9, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.FILLED)
	assert_almost_eq(_drink.fill_amount, 1.0, 0.01)
	
	_drink.fill(_drink_fountain_power)
	assert_eq(_drink.fill_state, Drink.FillState.OVERFILLING)
	assert_almost_eq(_drink.fill_amount, 1.1, 0.01)
