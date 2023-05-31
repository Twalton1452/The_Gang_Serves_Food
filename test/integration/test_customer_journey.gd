extends TestingUtils

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
	var menu_item : Array[SceneIds.SCENES] = [SceneIds.SCENES.BOTTOM_BUN, SceneIds.SCENES.PATTY, SceneIds.SCENES.TOMATO, SceneIds.SCENES.TOP_BUN]
	var menu_item_dish = create_combined_food(menu_item)
	
	(_restaurant.menu.get_child(-1) as MenuItem).dish_holder.hold_item(menu_item_dish)
	(_restaurant.menu.get_child(-1) as MenuItem)._on_holder_changed()
	
	# Act
	_customer_manager.spawn_party(num_customers_to_spawn)
	var spawned_party = _customer_manager.parties[0]
	spawned_party.think_time_sec = 0.1
	spawned_party.eating_time_sec = 0.1
	spawned_party.paying_time_sec = 0.1
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
	# So the Party transitions from WALKING_TO_ENTRY to WAITING_FOR_TABLE for less than a frame and then goes to WALKING_TO_TABLE
	assert_eq(spawned_party.state, CustomerParty.PartyState.WALKING_TO_TABLE, "The Party is not waiting for a table")
	
	# Act
	await wait_for_signal(spawned_party.state_changed, 1.0, "The party took to long waiting for a table")
	
	# Assert
	assert_not_null(spawned_party.table, "Party doesn't have a table")
	assert_eq(spawned_party.state, CustomerParty.PartyState.THINKING, "The Party is not walking to a table")
	for chair in spawned_party.table.chairs:
		assert_almost_eq(chair.sitter.global_position, chair.global_position, _acceptable_threshold, "The customer is not sitting in the chair correctly")
	
	# Act
	await wait_for_signal(spawned_party.state_changed, 1.0, "Party took too long to think about their order")
	assert_eq(spawned_party.state, CustomerParty.PartyState.ORDERING, "The Party is not ordering")
	for customer in spawned_party.customers:
		assert_eq(customer.order, menu_item, "Customer doesn't want food")
	
	for customer in spawned_party.customers:
		customer.player_interacted_with.emit() # pretend the player interacted with them
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "The party didn't order")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_FOR_FOOD, "Party isn't waiting for their food")
	
	for chair in _restaurant.tables[0].chairs:
		chair.holder.hold_item(menu_item_dish.duplicate())
		chair.holder.interacted.emit() # pretend the player put the item down
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Party never got their food")
	assert_eq(spawned_party.state, CustomerParty.PartyState.EATING, "Party is not eating")
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Party never ate their food")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_TO_PAY, "Party is not waiting to pay")
	
	for chair in _restaurant.tables[0].chairs:
		assert_eq(chair.holder.is_holding_item(), false, "There is still food on the table")
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Player never took the customer's money")
	assert_eq(spawned_party.state, CustomerParty.PartyState.PAYING, "Party is not paying")

	await wait_for_signal(spawned_party.state_changed, 2.0, "Party never paid")
	assert_eq(spawned_party.state, CustomerParty.PartyState.LEAVING, "Party is not leaving")
	
	assert_eq(len(_customer_manager.parties), 0, "Customer Manager didn't get cleaned up from the party leaving")
	assert_null(spawned_party, "Party never got deleted after leaving")

func test_party_can_wait_in_line():
	# Arrange
	var num_customers_to_spawn = 4
	_restaurant.tables = []
	
	# Act
	_customer_manager.spawn_party(num_customers_to_spawn)
	
	var table_wait_party = _customer_manager.parties[0]
	for customer in table_wait_party.customers:
		customer.speed = 3.0 # Go faster for the test
	await wait_for_signal(table_wait_party.state_changed, 3.0, "The first party took too long to get to the Entry")
	assert_eq(table_wait_party.state, CustomerParty.PartyState.WAITING_FOR_TABLE, "The first Party is not waiting for a table")
	
	# Act
	_customer_manager.spawn_party(num_customers_to_spawn)
	
	var line_wait_party = _customer_manager.parties[1]
	for customer in line_wait_party.customers:
		customer.speed = 3.0 # Go faster for the test
	assert_eq(line_wait_party.state, CustomerParty.PartyState.WALKING_TO_LINE, "The second Party is not waiting in line")
	await wait_for_signal(line_wait_party.state_changed, 3.0, "The second party took too long to get to the Entry")
	assert_eq(line_wait_party.state, CustomerParty.PartyState.WAITING_IN_LINE, "The second Party is not waiting in line")
	
	# Assert
	assert_eq(len(_customer_manager.parties), 2, "There are not the correct number of parties")
