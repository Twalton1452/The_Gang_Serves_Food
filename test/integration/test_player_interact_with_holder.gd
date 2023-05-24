extends GutTest

var PlayerScene = load("res://Scenes/player.tscn")
var HolderScene = load("res://Scenes/components/holder.tscn")
var PlateScene = load("res://Scenes/holders/plate_components.tscn")
var PattyScene = load("res://Scenes/foods/patty.tscn")

var MultiHolderClass = load("res://Scripts/MultiHolder.gd")

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

var multi_h_params = [
	[PattyScene, PattyScene, PattyScene],
	[PattyScene, PattyScene, null],
	[PattyScene, null, null],
	[null, null, null]
]

func test_holder_has_multiholder_with_varying_items_player_picks_up(params=use_parameters(multi_h_params)):
	var mult_h = MultiHolderClass.new()
	# Fill the MultiHolder
	for param in params:
		if param != null:
			var new_holder = HolderScene.instantiate()
			new_holder.add_child(param.instantiate())
			mult_h.add_child(new_holder)
		else:
			mult_h.add_child(HolderScene.instantiate())
	
	_holder.add_child(mult_h)
	
	assert_eq(len(_player.c_holder.get_held_items()), 0, "Player Holder doesn't have 0 items")
	assert_eq(_holder.get_held_item(), mult_h, "Holder not holding MultiHolder")
	
	_holder.interact(_player)

	assert_eq(_player.c_holder.get_held_item(), mult_h, "Player not holding MultiHolder")
	assert_eq(len(_holder.get_held_items()), 0, "Holder doesn't have 0 items")
