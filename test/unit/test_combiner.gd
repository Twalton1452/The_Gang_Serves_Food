extends GutTest

var PlayerScene = load("res://Scenes/player.tscn")
var TomatoScene = load("res://Scenes/foods/tomato.tscn")
var CupScene = load("res://Scenes/cup.tscn")

var _player : Player = null
var _holder : Holder = null

func before_each():
	_holder = Holder.new()
	add_child_autoqfree(_holder)
	_player = PlayerScene.instantiate()
	add_child_autoqfree(_player)
	_player.holder = add_child_autoqfree(Holder.new())

var non_combinables = [
	CupScene,
]

func test_player_cant_combine_with_non_food_items(non_combinable_scene=use_parameters(non_combinables)):
	var non_combinable : Holdable = add_child_autoqfree(non_combinable_scene.instantiate())
	_holder.hold_item(non_combinable)
	
	var player_tomato = add_child_autoqfree(TomatoScene.instantiate())
	_player.holder.hold_item(player_tomato)
	
	assert_eq(_holder.get_held_item(), non_combinable)
	assert_eq(_player.holder.get_held_item(), player_tomato)
	
	non_combinable.secondary_interact(_player)
	
	assert_eq(_holder.get_held_item(), non_combinable)
	assert_eq(_player.holder.get_held_item(), player_tomato)
