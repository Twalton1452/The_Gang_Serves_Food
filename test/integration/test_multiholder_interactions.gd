extends GutTest

var PlayerScene = load("res://Scenes/player.tscn")

var HolderClass = load("res://Scripts/Interactables/Holders/Holder.gd")
var HoldableClass = load("res://Scripts/Interactables/Holdables/Holdable.gd")
var MultiHolderClass = load("res://Scripts/Interactables/Holders/MultiHolder.gd")

var _player : Player = null
var _multi_h : MultiHolder = null

func before_each():
	_player = PlayerScene.instantiate()
	_multi_h = MultiHolderClass.new()
	add_child_autoqfree(_player)
	_player.holder.add_child(_multi_h)

func test_items_can_be_placed_and_picked_up():
	var items = [HoldableClass, HoldableClass, HoldableClass]
	var doubled_holder = partial_double(HolderClass, DOUBLE_STRATEGY.SCRIPT_ONLY)
	var to_interact_holders = [add_child_autoqfree(doubled_holder.new()), add_child_autoqfree(doubled_holder.new()), add_child_autoqfree(doubled_holder.new())]
	
	# Fill the MultiHolder
	for item in items:
		var holder = doubled_holder.new()
		stub(holder, "is_enabled").to_return(true)
		_multi_h.add_child(holder)
		_multi_h.holders.push_back(holder)
		holder.add_child(item.new())
	
	assert_eq(len(_player.holder.get_held_item().get_held_items()), 3, "Player Holder doesn't have 3 items")
	assert_eq(len(_multi_h.holders), 3, "MultiHolder has more/less Holders than intended")
	
	# Put all the items down with secondary_interact
	var i = 0
	for h in to_interact_holders:
		assert_eq(len(h.get_held_items()), 0, "Holder doesn't have 0 items")
		gut.p(len(h.get_held_items()) == 0)
		h.secondary_interact(_player)

		assert_eq(len(_multi_h.get_held_items()), 3 - (i + 1), "MultiHolder doesn't have the correct number of items")
		assert_eq(len(h.get_held_items()), 1, "Holder doesn't have 1 items")
		i += 1
	
	assert_eq(len(_multi_h.get_held_items()), 0, "MultiHolder didn't give away all its items")
	
	# Pick them back up with interact
	i = 0
	for h in to_interact_holders:
		assert_eq(len(_multi_h.get_held_items()), i, "MultiHolder doesn't have the correct amount of items")
		
		h.interact(_player)

		assert_eq(len(_multi_h.get_held_items()), 1 + i, "MultiHolder doesn't have the correct number of items")
		assert_eq(len(h.get_held_items()), 0, "Item wasn't given to Player")
		i += 1
	
	assert_eq(len(_multi_h.get_held_items()), 3, "MultiHolder didn't finish with the correct number of items")

