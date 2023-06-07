extends GutTest

class TestStackingHolderWithMultiHolders extends GutTest:
	
	var _plate : PackedScene = load("res://Scenes/holders/plate_components.tscn")
	var _stacking_holder : StackingHolder = null
	var _player : Player = null
	
	func before_each():
		_stacking_holder = StackingHolder.new()
		_stacking_holder.ingredient_scene = _plate
		_stacking_holder.hold_item(_plate.instantiate())
		_player = double(Player, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
		_player.holder = Holder.new()
		autofree(_stacking_holder)
		autofree(_player.holder)
		autofree(_player)
		
	
	func test_player_empty_hand_picks_up_from_stacking_holder():
		pass
