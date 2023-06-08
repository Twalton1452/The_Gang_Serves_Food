extends GutTest

var _drink : Drink = null
var _drink_fountain_power = 0.1
var _beverage : Beverage = load("res://Resources/Beverages/Beverage_Water.tres")

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
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.EMPTY)
	assert_almost_eq(_drink.fill_amount, 0.1, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.2, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.3, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.4, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.5, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.PARTIAL_FILLED)
	assert_almost_eq(_drink.fill_amount, 0.6, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.FILLED)
	assert_almost_eq(_drink.fill_amount, 0.7, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.FILLED)
	assert_almost_eq(_drink.fill_amount, 0.8, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.FILLED)
	assert_almost_eq(_drink.fill_amount, 0.9, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.FILLED)
	assert_almost_eq(_drink.fill_amount, 1.0, 0.01)
	
	_drink.fill(_drink_fountain_power, _beverage)
	assert_eq(_drink.fill_state, Drink.FillState.OVERFILLING)
	assert_almost_eq(_drink.fill_amount, 1.1, 0.01)
	assert_almost_eq(_drink.beverage_amounts[_beverage.display_name], 1.1, 0.01)

func test_drink_can_be_drank():
	_drink.fill_amount = 1.0
	_drink.beverage_amounts[NetworkedResources.get_resource_by_id(NetworkedIds.Resources.WATER)] = 1.0
	
	_drink.gulp()
	
	assert_eq(_drink.fill_amount, 0.0)
	assert_eq(_drink.fill_state, Drink.FillState.EMPTY)
	assert_eq(_drink.beverage_amounts, {})
	
