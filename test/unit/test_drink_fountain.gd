extends GutTest

var DrinkFountainScene = load("res://Scenes/drink_fountain.tscn")

var _drink_fountain : DrinkFountain = null

func before_each():
	_drink_fountain = DrinkFountainScene.instantiate()
	add_child_autoqfree(_drink_fountain)

func test_drink_fountain_sees_item_enter_and_leave_dispenser_zone():
	var drink : Drink = Drink.new()
	var holder : Holder = Holder.new()
	add_child_autoqfree(drink)
	add_child_autoqfree(holder)
	assert_eq(_drink_fountain.dispenser_holder.is_holding_item(), false)
	
	_drink_fountain.dispenser_holder.hold_item(drink)
	
	assert_eq(_drink_fountain.dispenser_holder.is_holding_item(), true)
	assert_eq(_drink_fountain.dispenser_holder.get_held_item(), drink)
	assert_eq(_drink_fountain.filling_drink, drink)
	assert_eq(_drink_fountain.fill_rate_timer.is_stopped(), false)
	
	_drink_fountain.dispenser_holder.release_item_to(holder)
	assert_null(_drink_fountain.filling_drink)
	assert_eq(_drink_fountain.dispenser_holder.is_holding_item(), false)
	assert_eq(_drink_fountain.fill_rate_timer.is_stopped(), true)
	assert_eq(holder.get_held_item(), drink)

func test_drink_fountain_can_fill_drink():
	var drink : Drink = Drink.new()
	add_child_autoqfree(drink)
	assert_eq(_drink_fountain.dispenser_holder.is_holding_item(), false)
	
	_drink_fountain.dispenser_holder.hold_item(drink)
	
	assert_eq(_drink_fountain.dispenser_holder.is_holding_item(), true)
	assert_eq(_drink_fountain.dispenser_holder.get_held_item(), drink)
	assert_eq(_drink_fountain.filling_drink, drink)
	assert_eq(_drink_fountain.fill_rate_timer.is_stopped(), false)
	
	_drink_fountain.fill_rate = 0.1
	for i in range(10):
		_drink_fountain._on_fill_rate_tick()
	
	assert_eq(_drink_fountain.filling_drink.fill_state, Drink.FillState.FILLED)
