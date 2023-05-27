extends GutTest

var RestaurantScene = load("res://test/Scenes/test_restaurant.tscn")

var _restaurant : Restaurant = null
var _customer_manager : CustomerManager = null

func before_each():
	_restaurant = RestaurantScene.instantiate()
	add_child_autoqfree(_restaurant)
	_customer_manager = _restaurant.get_node("CustomerManager")
	_customer_manager.restaurant = _restaurant
	#watch_signals(_customer_manager)

func test_party_spawns_sits_at_available_table():
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
	# Check everyone made it
	assert_eq(spawned_party.num_arrived_to_destination, num_customers_to_spawn, "Not everyone made it to the entry")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_FOR_TABLE, "The Party is not waiting for a table")
	
	# Act
	#await wait_for_signal(spawned_party.state_change, 3.0, "The party didn't change their state")
	#_customer_manager.evaluate_parties()
	# Assert
