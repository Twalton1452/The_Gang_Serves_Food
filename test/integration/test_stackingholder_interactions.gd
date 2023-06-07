extends GutTest

class TestStackingHolderWithMultiHolders extends TestingUtils:
	var PlayerScene = load("res://Scenes/player.tscn")
	
	var PlateScene : PackedScene = load("res://Scenes/holders/plate_components.tscn")
	var _stacking_holder : StackingHolder = null
	var _plate : MultiHolder = null
	var _player : Player = null
	
	func before_each():
		_stacking_holder = StackingHolder.new()
		_stacking_holder.ingredient_scene = PlateScene
		_stacking_holder.max_amount = 100
		add_child_autoqfree(_stacking_holder)
		_plate = PlateScene.instantiate()
		_stacking_holder.hold_item(_plate)
		_player = PlayerScene.instantiate()
		add_child_autoqfree(_player)
		_player.holder = add_child_autoqfree(Holder.new())
	
	func test_player_empty_hand_picks_up_from_stacking_holder():
		assert_eq(_player.holder.is_holding_item(), false)
		assert_eq(_stacking_holder.is_holding_item(), true)
		assert_eq(_stacking_holder.get_held_item(), _plate)
		
		_plate.interact(_player)
		
		assert_eq(_player.holder.is_holding_item(), true)
		assert_eq(_player.holder.get_held_item(), _plate)
		assert_eq(_stacking_holder.is_holding_item(), false)

	func test_player_has_holdable_can_plate_from_stacking_holder():
		var patty = load("res://Scenes/foods/patty.tscn").instantiate()
		_player.holder.hold_item_unsafe(patty)
		assert_eq(_player.holder.is_holding_item(), true)
		assert_eq(_stacking_holder.is_holding_item(), true)
		assert_eq(_stacking_holder.get_held_item(), _plate)
		
		_plate.interact(_player)
		
		assert_eq(_player.holder.is_holding_item(), true)
		assert_eq(_player.holder.get_held_item(), _plate)
		assert_eq(_plate.is_holding_item(), true)
		assert_eq(_plate.get_held_item(), patty)
		assert_eq(_stacking_holder.is_holding_item(), false)
	
	func test_player_has_combined_food_can_plate_from_stacking_holder():
		var combined_food = create_combined_food([NetworkedIds.Scene.ONION, NetworkedIds.Scene.ONION])
		_player.holder.hold_item_unsafe(combined_food)
		assert_eq(_player.holder.is_holding_item(), true)
		assert_eq(_stacking_holder.is_holding_item(), true)
		assert_eq(_stacking_holder.get_held_item(), _plate)
		
		_plate.interact(_player)
		
		assert_eq(_player.holder.is_holding_item(), true)
		assert_eq(_player.holder.get_held_item(), _plate)
		assert_eq(_plate.is_holding_item(), true)
		assert_eq(_plate.get_held_item(), combined_food)
		assert_eq(_stacking_holder.is_holding_item(), false)
