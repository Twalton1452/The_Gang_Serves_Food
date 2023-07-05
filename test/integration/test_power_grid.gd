extends GutTest

var PowerGeneratorScene = load("res://Scenes/accumulators/power_transformer.tscn")
var PowerConsumingScene = load("res://Scenes/accumulators/small_accumulator.tscn")

var _generator : PowerGenerator = null
var _accumulator : Accumulator = null

func before_each():
	GameState.hud = double(HUD, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	PowerGrid.timer.stop()
	PowerGrid.tick_rate_seconds = 1.0
	
	_generator = PowerGeneratorScene.instantiate()
	_accumulator = PowerConsumingScene.instantiate()
	add_child_autoqfree(_generator)
	add_child_autoqfree(_accumulator)
	_accumulator.accumulate_timer.stop()
	assert_eq(get_tree().get_nodes_in_group(PowerGenerator.GENERATOR_GROUP).size(), 1, "No Generators in Generator Group")

func test_power_grid_generates_power_from_power_generators() -> void:
	_generator.stored_amount = 0.0
	assert_eq(_generator.stored_amount, 0.0)
	PowerGrid._on_tick()
	assert_eq(_generator.stored_amount, _generator.potential_power_per_tick)

func test_power_consumer_consumes_enough_to_function() -> void:
	var original_power = 100.0
	var power_to_consume_for_action = 1.0
	_generator.stored_amount = original_power
	_accumulator.consumption_per_action = power_to_consume_for_action
	
	assert_eq(_accumulator.accumulated_power, 0.0)
	_accumulator.power_dependent_action()
	assert_eq(_accumulator.accumulated_power, 0.0)
	
	assert_eq(_generator.stored_amount, original_power - power_to_consume_for_action)

func test_power_consumer_consumes_enough_to_function_from_multiple_generators() -> void:
	var original_power = 1.0
	var power_to_consume_for_action = 2.0
	_generator.stored_amount = original_power
	var second_generator = PowerGeneratorScene.instantiate()
	add_child_autoqfree(second_generator)
	second_generator.stored_amount = original_power
	_accumulator.consumption_per_action = power_to_consume_for_action
	
	assert_eq(_accumulator.accumulated_power, 0.0)
	_accumulator.power_dependent_action()
	assert_eq(_accumulator.accumulated_power, 0.0)
	
	assert_eq(_generator.stored_amount, 0.0)
	assert_eq(second_generator.stored_amount, 0.0)

func test_power_consumer_eventually_consumes_enough_to_function() -> void:
	var original_power = 1.0
	var power_to_consume_for_action = 2.0
	_generator.stored_amount = original_power
	_generator.potential_power_per_tick = original_power
	_accumulator.consumption_per_action = power_to_consume_for_action
	assert_eq(_accumulator.power_sprite.visible, false)
	
	assert_eq(_accumulator.accumulated_power, 0.0)
	var action_was_executed = _accumulator.power_dependent_action()
	assert_eq(_accumulator.power_sprite.visible, true)
	assert_eq(action_was_executed, false)
	assert_eq(_accumulator.accumulated_power, original_power)
	
	PowerGrid._on_tick()
	action_was_executed = _accumulator.power_dependent_action()
	assert_eq(action_was_executed, true)
	assert_eq(_accumulator.accumulated_power, 0.0)
	assert_eq(_accumulator.power_sprite.visible, false)
	
	assert_eq(_generator.stored_amount, 0.0)


