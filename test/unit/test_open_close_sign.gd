extends GutTest

var OpenCloseSignScene = load("res://Scenes/sign.tscn")

var _sign : OpenCloseSign = null

func before_each() -> void:
	GameState.STATE_VALIDATIONS = {}
	GameState.hud = double(HUD, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	GameState.state = GameState.Phase.OPEN_FOR_BUSINESS
	_sign = OpenCloseSignScene.instantiate()
	add_child_autoqfree(_sign)
	_sign.rotatable.time_to_rotate_seconds = 0.1
	
func test_rotating_sign_transitions_game_state() -> void:
	assert_eq(GameState.state, GameState.Phase.OPEN_FOR_BUSINESS)
	_sign.rotatable.interact(null)
	await wait_for_signal(_sign.rotatable.rotated, 0.2)
	assert_eq(GameState.state, GameState.Phase.EDITING_RESTAURANT)
	_sign.rotatable.interact(null)
	await wait_for_signal(_sign.rotatable.rotated, 0.2)
	assert_eq(GameState.state, GameState.Phase.OPEN_FOR_BUSINESS)
