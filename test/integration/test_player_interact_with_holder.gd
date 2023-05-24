extends GutTest

var PlayerScene = load("res://Scenes/player.tscn")
var HolderScene = load("res://Scenes/components/holder.tscn")
var PattyScene = load("res://Scenes/foods/patty.tscn")

var _player : Player = null
var _holder : Holder = null

func before_each():
	_player = PlayerScene.instantiate()
	_holder = HolderScene.instantiate()
	add_child_autoqfree(_player)
	add_child_autoqfree(_holder)

func test_player_has_item_gives_empty_holder_item():
	var patty : Holdable = PattyScene.instantiate()
	
	_player.c_holder.add_child(patty)
	
	assert_eq(len(_holder.get_held_items()), 0, "Holder doesn't have 0 items")
	assert_eq(len(_player.c_holder.get_held_items()), 1, "Player Holder doesn't have 1 items")
	
	_holder.interact(_player)
	
	assert_eq(len(_holder.get_held_items()), 1, "Holder doesn't have 1 items")
	assert_eq(len(_player.c_holder.get_held_items()), 0, "Player Holder doesn't have 0 items")

func test_holder_has_item_gives_empty_player_item():
	var patty : Holdable = PattyScene.instantiate()
	
	_holder.add_child(patty)
	
	assert_eq(len(_holder.get_held_items()), 1, "Holder doesn't have 1 items")
	assert_eq(len(_player.c_holder.get_held_items()), 0, "Player Holder doesn't have 0 items")
	
	_holder.interact(_player)
	
	assert_eq(len(_holder.get_held_items()), 0, "Holder doesn't have 0 items")
	assert_eq(len(_player.c_holder.get_held_items()), 1, "Player Holder doesn't have 1 items")
	
func test_player_and_holder_have_item_swaps():
	var patty : Holdable = PattyScene.instantiate()
	var patty_two : Holdable = PattyScene.instantiate()
	
	_player.c_holder.add_child(patty)
	_holder.add_child(patty_two)
	
	assert_eq(_player.c_holder.get_held_item(), patty, "Player not holding Patty")
	assert_eq(_holder.get_held_item(), patty_two, "Holder not holding Patty two")
	
	_holder.interact(_player)

	assert_eq(_player.c_holder.get_held_item(), patty_two, "Player not holding Patty two")
	assert_eq(_holder.get_held_item(), patty, "Holder not holding Patty")
