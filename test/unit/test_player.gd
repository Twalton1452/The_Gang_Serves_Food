extends GutTest

var PlayerScene = load("res://Scenes/player.tscn")

var _player : Player = null

func before_each():
	_player = PlayerScene.instantiate()
	_player.name = "1" # for authority purposes
	add_child_autoqfree(_player)
	_player.init()

func test_can_switch_holders():
	assert_eq(_player.holder, _player.interact_holder)
	assert_eq(_player.interact_ray_cast.enabled, true)
	assert_eq(_player.edit_mode_ray_cast.enabled, false)
	
	_player.switch_to_edit_mode_hand()
	assert_eq(_player.holder, _player.edit_mode_holder)
	assert_eq(_player.interact_ray_cast.enabled, false)
	assert_eq(_player.edit_mode_ray_cast.enabled, true)
	
	_player.switch_to_interactable_hand()
	assert_eq(_player.holder, _player.interact_holder)
	assert_eq(_player.interact_ray_cast.enabled, true)
	assert_eq(_player.edit_mode_ray_cast.enabled, false)
	
