extends GutTest

var RestaurantScene = load("res://test/Scenes/test_restaurant.tscn")

var _restaurant : Restaurant = null
var _customer_manager : CustomerManager = null
var _acceptable_threshold = Vector3(.3, .3, .3)

func before_each():
	_restaurant = RestaurantScene.instantiate()
	add_child_autoqfree(_restaurant)
	_customer_manager = _restaurant.get_node("CustomerManager")
	_customer_manager.restaurant = _restaurant
	#watch_signals(_customer_manager)

func test_party_full_journey():
	# Arrange
	var num_customers_to_spawn = 4
	
	# Act
	_customer_manager.spawn_party(num_customers_to_spawn)
	var spawned_party = _customer_manager.parties[0]
	for customer in spawned_party.customers:
		customer.speed = 3.0 # Go faster for the test
	await wait_frames(2) # Let the physics process tick to calculate nav_agent path's
	
	# Assert
	assert_eq(spawned_party.customers[0].nav_agent.is_target_reachable(), true, "Customers cannot find a path")
	assert_eq(len(_customer_manager.parties), 1, "There are not the correct number of parties")
	assert_eq(len(spawned_party.customers), num_customers_to_spawn, "There are not the correct number of customers")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WALKING_TO_ENTRY, "The Party is not walking to the entry")
	await wait_for_signal(spawned_party.state_changed, 3.0, "The party took too long to get to the Entry")
	# Note: Should be WAITING_FOR_TABLE for a single frame, but the wait_for_signal processes AFTER the logic happens
	# So CustomerManager is handling it before we can check on the state.
	assert_eq(spawned_party.state, CustomerParty.PartyState.WALKING_TO_TABLE, "The Party is not waiting for a table")
	
	# Act
	await wait_for_signal(spawned_party.state_changed, 1.0, "The party took to long waiting for a table")
	assert_not_null(spawned_party.table, "Party doesn't have a table")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WALKING_TO_TABLE, "The Party is not walking to a table")
	
	await wait_for_signal(spawned_party.state_changed, 2.0, "The party took too long walking to the table")
	assert_eq(spawned_party.state, CustomerParty.PartyState.THINKING, "The Party is not thinking at a table")
	for chair in spawned_party.table.chairs:
		assert_almost_eq(chair.sitter.global_position, chair.global_position, _acceptable_threshold, "The customer is not sitting in the chair correctly")
	#_customer_manager.evaluate_parties()
	# Assert
