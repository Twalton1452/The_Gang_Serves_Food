extends GutTest

var AccumulatorScene = load("res://Scenes/accumulators/small_accumulator.tscn")
var AccumulateScene = load("res://Scenes/foods/patty.tscn")

var _accumulator : Accumulator = null

func before_each() -> void:
	GameState.hud = double(HUD, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	GameState.state = GameState.Phase.OPEN_FOR_BUSINESS
	_accumulator = AccumulatorScene.instantiate()
	add_child_autoqfree(_accumulator)
	_accumulator.to_accumulate_scene = AccumulateScene
	_accumulator.accumulate_timer.stop()

func test_can_accumulate_item() -> void:
	_accumulator.holder.max_amount = 2
	assert_eq(_accumulator.holder.get_held_items().size(), 0)
	assert_eq(_accumulator.display.get_children().size(), 1)
	
	_accumulator.accumulate()
	
	assert_eq(_accumulator.holder.get_held_items().size(), 1)
	assert_eq(_accumulator.display.get_children().size(), 1)

	_accumulator.accumulate()
#
	assert_eq(_accumulator.holder.get_held_items().size(), 2)
	assert_eq(_accumulator.display.get_children().size(), 1)

	_accumulator.accumulate()

	assert_eq(_accumulator.holder.get_held_items().size(), 2)
	assert_eq(_accumulator.display.get_children().size(), 1)
