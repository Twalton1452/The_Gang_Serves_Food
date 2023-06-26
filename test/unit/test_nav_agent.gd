extends GutTest

var PlaygroundScene = load("res://test/Scenes/test_playground.tscn")
var CustomerScene = load("res://Scenes/customer.tscn")

var _playground : NavigationRegion3D = null
var _customer : Customer = null
var _customer_spawn = Vector3(0.0, 0.3, 0.0)
var _acceptable_threshold = Vector3(.7, 1000, .7)

func before_each():
	GameState.hud = double(HUD, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	GameState.state = GameState.Phase.LOBBY
	_playground = PlaygroundScene.instantiate()
	add_child_autoqfree(_playground)
	_customer = CustomerScene.instantiate()
	_playground.add_child(_customer)
	_customer.global_position = _customer_spawn
	_customer.speed = 7.0

func test_customer_moves_to_target_and_back():
	# Arrange
	var target = Vector3(0.0, _customer_spawn.y, 2.0)
	assert_eq(_customer.global_position, _customer_spawn, "Customer isn't starting from spawn")
	
	# Act
	_customer.go_to(target)
	await wait_frames(2) # Let the navmesh calculate the path after updating the target
	
	# Assert
	assert_eq(_customer.nav_agent.is_target_reachable(), true, "Customer's target isn't reachable")
	await wait_for_signal(_customer.arrived, 3.0, "Customer never reached its destination")
	assert_almost_eq(_customer.global_position, target, _acceptable_threshold, "Customer didn't make it to its target")
	
	# Arrange
	target = _customer_spawn
	
	# Act
	_customer.go_to(target)
	await wait_frames(2) # Let the navmesh calculate the path after updating the target
	
	# Assert
	assert_eq(_customer.nav_agent.is_target_reachable(), true, "Customer's spawn isn't reachable")
	await wait_for_signal(_customer.arrived, 3.0, "Customer never reached back to spawn")
	assert_almost_eq(_customer.global_position, target, _acceptable_threshold, "Customer didn't make it to its target")
