extends GutTest

## Each test the Holder being interacted with will start with no item
class TestHolderWithNoItem extends GutTest:
	var PlayerScene = load("res://Scenes/player.tscn")
	var HolderClass = load("res://Scripts/Holder.gd")
	var HoldableClass = load("res://Scripts/Holdable.gd")
	var MultiHolderClass = load("res://Scripts/MultiHolder.gd")

	var _player : Player = null
	var _holder : Holder = null

	func before_each():
		_player = PlayerScene.instantiate()
		_holder = HolderClass.new()
		add_child_autoqfree(_player)
		add_child_autoqfree(_holder)

	func test_player_has_item():
		var holdable : Holdable = HoldableClass.new()
		
		_player.c_holder.add_child(holdable)
		
		assert_eq(len(_holder.get_held_items()), 0, "Holder doesn't have 0 items")
		assert_eq(len(_player.c_holder.get_held_items()), 1, "Player Holder doesn't have 1 items")
		
		_holder.interact(_player)
		
		assert_eq(len(_holder.get_held_items()), 1, "Holder doesn't have 1 items")
		assert_eq(len(_player.c_holder.get_held_items()), 0, "Player Holder doesn't have 0 items")

## Each test the Holder being interacted with will start with a Holdable
class TestHolderWithHoldable extends GutTest:
	var PlayerScene = load("res://Scenes/player.tscn")
	var HolderClass = load("res://Scripts/Holder.gd")
	var HoldableClass = load("res://Scripts/Holdable.gd")
	var MultiHolderClass = load("res://Scripts/MultiHolder.gd")

	var _player : Player = null
	var _holder : Holder = null

	func before_each():
		_player = PlayerScene.instantiate()
		_holder = HolderClass.new()
		add_child_autoqfree(_player)
		add_child_autoqfree(_holder)

	func test_player_has_no_item_gives_player_item():
		var holdable : Holdable = HoldableClass.new()
		
		_holder.add_child(holdable)
		
		assert_eq(len(_holder.get_held_items()), 1, "Holder doesn't have 1 items")
		assert_eq(len(_player.c_holder.get_held_items()), 0, "Player Holder doesn't have 0 items")
		
		_holder.interact(_player)
		
		assert_eq(len(_holder.get_held_items()), 0, "Holder doesn't have 0 items")
		assert_eq(len(_player.c_holder.get_held_items()), 1, "Player Holder doesn't have 1 items")

	func test_player_has_item_swaps_with_holder():
		var holdable : Holdable = HoldableClass.new()
		var holdable_two : Holdable = HoldableClass.new()
		
		_player.c_holder.add_child(holdable)
		_holder.add_child(holdable_two)
		
		assert_eq(_player.c_holder.get_held_item(), holdable, "Player not holding Holdable")
		assert_eq(_holder.get_held_item(), holdable_two, "Holder not holding Holdable two")
		
		_holder.interact(_player)

		assert_eq(_player.c_holder.get_held_item(), holdable_two, "Player not holding Holdable two")
		assert_eq(_holder.get_held_item(), holdable, "Holder not holding Holdable")

	func test_player_has_multiholder_picks_up_holdable():
		var multi_h = MultiHolderClass.new()
		var holdable : Holdable = HoldableClass.new()
		var holder = partial_double(HolderClass, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
		stub(holder, "is_enabled").to_return(true)
		multi_h.add_child(holder)
		
		_player.c_holder.add_child(multi_h)
		_holder.add_child(holdable)
		
		assert_eq(_player.c_holder.get_held_item(), multi_h, "Player not holding MultiHolder")
		assert_eq(len(_player.c_holder.get_held_item().c_holders), 1, "Player's MultiHolder doesn't have 1 Holder")
		assert_eq(len(_player.c_holder.get_held_item().get_held_items()), 0, "Player's MultiHolder holding something")
		assert_eq(_holder.get_held_item(), holdable, "Holder not holding Holdable")
		
		_holder.interact(_player)

		assert_eq(_player.c_holder.get_held_item(), multi_h, "Player not holding MultiHolder")
		assert_eq(_player.c_holder.get_held_item().get_held_item(), holdable, "Player's MultiHolder not holding Holdable")
		assert_eq(len(_holder.get_held_items()), 0, "Holder holding something")

## Each test the Holder being interacted with will start with a MultiHolder
class TestHolderWithMultiHolder extends GutTest:

	var PlayerScene = load("res://Scenes/player.tscn")
	
	var HolderClass = load("res://Scripts/Holder.gd")
	var HoldableClass = load("res://Scripts/Holdable.gd")
	var MultiHolderClass = load("res://Scripts/MultiHolder.gd")
	var StackingHolderClass = load("res://Scripts/StackingHolder.gd")

	var _player : Player = null
	var _holder : Holder = null

	func before_each():
		_player = PlayerScene.instantiate()
		_holder = HolderClass.new()
		add_child_autoqfree(_player)
		add_child_autoqfree(_holder)

	var multi_h_params = [
		[HoldableClass, HoldableClass, HoldableClass],
		[HoldableClass, HoldableClass, null],
		[HoldableClass, null, null],
		[null, null, null]
	]

	func test_varying_items_player_picks_up_multiholder(params=use_parameters(multi_h_params)):
		var multi_h = MultiHolderClass.new()
		# Fill the MultiHolder
		for param in params:
			if param != null:
				var new_holder = HolderClass.new()
				new_holder.add_child(param.new())
				multi_h.add_child(new_holder)
			else:
				multi_h.add_child(HolderClass.new())
		
		_holder.add_child(multi_h)
		
		assert_eq(len(_player.c_holder.get_held_items()), 0, "Player Holder doesn't have 0 items")
		assert_eq(_holder.get_held_item(), multi_h, "Holder not holding MultiHolder")
		
		_holder.interact(_player)

		assert_eq(_player.c_holder.get_held_item(), multi_h, "Player not holding MultiHolder")
		assert_eq(len(_holder.get_held_items()), 0, "Holder doesn't have 0 items")

	func test_empty_multiholder_player_has_holdable_does_nothing():
		var multi_h = MultiHolderClass.new()
		var holdable : Holdable = HoldableClass.new()
		multi_h.add_child(HolderClass.new())
		
		_player.c_holder.add_child(holdable)
		_holder.add_child(multi_h)
		
		assert_eq(_player.c_holder.get_held_item(), holdable, "Player not holding Holdable")
		assert_eq(_holder.get_held_item(), multi_h, "Holder not holding MultiHolder")
		
		_holder.interact(_player)

		assert_eq(_player.c_holder.get_held_item(), holdable, "Player not holding Holdable")
		assert_eq(_holder.get_held_item(), multi_h, "Holder not holding MultiHolder")

	func test_empty_multiholder_player_has_empty_multiholder_does_nothing():
		var multi_h = MultiHolderClass.new()
		var holder_multi_h = MultiHolderClass.new()
		var holder = partial_double(HolderClass, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
		var holder_two = partial_double(HolderClass, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
		
		stub(holder, "is_enabled").to_return(true)
		stub(holder_two, "is_enabled").to_return(true)
		
		multi_h.add_child(holder)
		holder_multi_h.add_child(holder_two)
		
		_player.c_holder.add_child(multi_h)
		_holder.add_child(holder_multi_h)
		
		assert_eq(_player.c_holder.get_held_item(), multi_h, "Player not holding MultiHolder")
		assert_eq(len(_player.c_holder.get_held_item().c_holders), 1, "Player's MultiHolder doesn't have 1 Holder")
		assert_eq(len(_player.c_holder.get_held_item().get_held_items()), 0, "Player's MultiHolder holding something")
		
		assert_eq(_holder.get_held_item(), holder_multi_h, "Holder not holding MultiHolder")
		assert_eq(len(_holder.get_held_item().c_holders), 1, "Holder's MultiHolder doesn't have 1 Holder")
		assert_eq(len(_holder.get_held_item().get_held_items()), 0, "Holder's MultiHolder holding something")
		
		_holder.interact(_player)

		assert_eq(_player.c_holder.get_held_item(), multi_h, "Player not holding original MultiHolder")
		assert_eq(len(_player.c_holder.get_held_item().get_held_items()), 0, "Player's MultiHolder holding something")
		
		assert_eq(_holder.get_held_item(), holder_multi_h, "Holder not holding original MultiHolder")
		assert_eq(len(_holder.get_held_item().get_held_items()), 0, "Holder's MultiHolder holding something")

## Each test the Holder being interacted with will start with a StackingHolder as a child
class TestHolderWithStackingHolder extends GutTest:
	var PlayerScene = load("res://Scenes/player.tscn")
	
	var HolderClass = load("res://Scripts/Holder.gd")
	var HoldableClass = load("res://Scripts/Holdable.gd")
	var MultiHolderClass = load("res://Scripts/MultiHolder.gd")
	var StackingHolderClass = load("res://Scripts/StackingHolder.gd")

	var _player : Player = null
	var _holder : Holder = null
	var _stacking_h : StackingHolder = null
	
	func before_each():
		_player = PlayerScene.instantiate()
		_holder = HolderClass.new()
		add_child_autoqfree(_player)
		add_child_autoqfree(_holder)
		_stacking_h = StackingHolderClass.new()
		_holder.add_child(_stacking_h)
		
	func test_empty_stackingholder_player_has_empty_multiholder_does_nothing():
		var multi_h = MultiHolderClass.new()
		var holder = partial_double(HolderClass, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
		
		stub(holder, "is_enabled").to_return(true)
		
		multi_h.add_child(holder)
		_player.c_holder.add_child(multi_h)
		
		assert_eq(_player.c_holder.get_held_item(), multi_h, "Player not holding MultiHolder")
		assert_eq(len(_player.c_holder.get_held_item().c_holders), 1, "Player's MultiHolder doesn't have 1 Holder")
		assert_eq(len(_player.c_holder.get_held_item().get_held_items()), 0, "Player's MultiHolder holding something")
		
		assert_eq(_holder.get_held_item(), _stacking_h, "Holder not holding StackingHolder")
		assert_eq(len(_holder.get_held_item().get_held_items()), 0, "Holder's StackingHolder has items")
		
		_holder.interact(_player)

		assert_eq(_player.c_holder.get_held_item(), multi_h, "Player not holding original MultiHolder")
		assert_eq(len(_player.c_holder.get_held_item().get_held_items()), 0, "Player's MultiHolder holding something")
		
		assert_eq(_holder.get_held_item(), _stacking_h, "Holder not holding original StackingHolder")
		assert_eq(len(_holder.get_held_item().get_held_items()), 0, "Holder's StackingHolder holding something")
