extends TestingUtils

var RestaurantScene = load("res://test/Scenes/test_restaurant.tscn")

var _restaurant : Restaurant = null
var _customer_manager : CustomerManager = null
var _acceptable_threshold = Vector3(.3, .3, .3)

func _wait_for_party_to_reach(party: CustomerParty, state: CustomerParty.PartyState):
	for i in range(party.state, state + 1):
		if party.state == state or party.state > state:
			return
		await wait_for_signal(party.state_changed, 1.0, "The party took too long to get to the desired state")

func _spawn_test_party(num_customers: int) -> CustomerParty:
	_customer_manager.spawn_party(num_customers)
	var spawned_party = _customer_manager.parties[-1]
	spawned_party.think_time_sec = 0.1
	spawned_party.eating_time_sec = 0.1
	spawned_party.paying_time_sec = 0.1
	spawned_party.wait_before_leave_time_sec = 0.1
	for customer in spawned_party.customers:
		watch_signals(customer)
		customer.speed = 5.0
	return spawned_party

func _set_test_menu_to(dish: Array[NetworkedIds.Scene]) -> CombinedFoodHolder:
	var menu_item_dish = create_combined_food(dish)
	(_restaurant.menu.get_child(-1) as MenuItem).dish_holder.hold_item(menu_item_dish)
	(_restaurant.menu.get_child(-1) as MenuItem)._on_holder_changed()
	return menu_item_dish

func before_each():
	_restaurant = RestaurantScene.instantiate()
	add_child_autoqfree(_restaurant)
	_customer_manager = _restaurant.get_node("CustomerManager")
	_customer_manager.restaurant = _restaurant
	_customer_manager.max_parties = 1
	_customer_manager.min_wait_to_spawn_sec = 998
	_customer_manager.max_wait_to_spawn_sec = 999
	#watch_signals(_customer_manager)

func test_party_full_journey():
	
	# Arrange 
	var num_customers_to_spawn = 4
	var menu_item : Array[NetworkedIds.Scene] = [NetworkedIds.Scene.BOTTOM_BUN, NetworkedIds.Scene.PATTY, NetworkedIds.Scene.TOMATO, NetworkedIds.Scene.TOP_BUN]
	var menu_item_dish = _set_test_menu_to(menu_item)
	
	# Act
	var spawned_party = _spawn_test_party(num_customers_to_spawn)
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
	assert_eq(spawned_party.num_customers_required_to_advance, 1, "Player should only need to talk to 1 customer to initiate waiting for food")
	for customer in spawned_party.customers:
		assert_eq_deep(customer.order, menu_item)
		assert_eq(customer.interactable.is_enabled(), true, "Customer isn't interactable when they should be")
		assert_not_null(customer.order_visual, "There is no visual for the customer's order")
		var visual_items = customer.order_visual.get_held_items()
		assert_eq(visual_items.size(), customer.order.size(), "Visual doesn't match the Order")
		for i in len(customer.order):
			var visual = visual_items[i]
			var order = customer.order[i]
			assert_eq(visual.SCENE_ID, order, "The visuals for the order is in the wrong places")
		assert_almost_eq(customer.order_visual.global_position, customer.sitting_chair.holder.global_position, Vector3(0.2, 0.2, 0.2))
		assert_eq(customer.order_visual.visible, false, "The order visual is showing too early")
	
	spawned_party.customers[0]._on_player_interacted() # pretend the player interacted with a customer
	
	for customer in spawned_party.customers:
		assert_eq(customer.interactable.is_enabled(), false, "Customer is interactable when they shouldn't be")
		assert_eq(customer.order_visual.visible, true, "The order visual isn't showing")
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "The party didn't order")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_FOR_FOOD, "Party isn't waiting for their food")
	
	for chair in _restaurant.tables[0].chairs:
		chair.holder.hold_item(menu_item_dish.duplicate())
		chair.holder.interacted.emit() # pretend the player put the item down
	
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Party never got their food")
	assert_eq(spawned_party.state, CustomerParty.PartyState.EATING, "Party is not eating")
	
	for customer in spawned_party.customers:
		assert_null(customer.order_visual, "The order visual still exists after being given food")
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Party never ate their food")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_TO_PAY, "Party is not waiting to pay")
	assert_eq(spawned_party.num_customers_required_to_advance, 1, "Player should only need to talk to 1 customer to initiate paying")
	var player_interactions = 0
	for customer in spawned_party.customers:
		player_interactions += get_signal_emit_count(customer, "player_interacted_with")
		assert_signal_emit_count(customer, "got_order", 1)
		assert_signal_emit_count(customer, "ate_food", 1)
		assert_eq(customer.interactable.is_enabled(), true, "Customer isn't interactable when they should be")
	assert_eq(player_interactions, 1, "Customers were not interacted with the expected number of times")
		
	for chair in _restaurant.tables[0].chairs:
		assert_eq(chair.holder.is_holding_item(), false, "There is still food on the table")
	
	spawned_party.customers[0]._on_player_interacted() # pretend the player interacted with a customer
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Player never took the customer's money")
	assert_eq(spawned_party.state, CustomerParty.PartyState.PAYING, "Party is not paying")
	
	player_interactions = 0
	for customer in spawned_party.customers:
		player_interactions += get_signal_emit_count(customer, "player_interacted_with")
		assert_signal_emit_count(customer, "got_order", 1)
		assert_signal_emit_count(customer, "ate_food", 1)
	assert_eq(player_interactions, 2, "Customers were not interacted with the expected number of times")
	
	await wait_for_signal(spawned_party.state_changed, 2.0, "Party never paid")
	assert_eq(spawned_party.state, CustomerParty.PartyState.LEAVING_FOR_HOME, "Party is not leaving")
	assert_eq(spawned_party.num_customers_required_to_advance, 1, "Only 1 customer needs to make it to the exit zone")
	assert_null(spawned_party.table)
	
	await wait_for_signal(spawned_party.state_changed, 3.0, "Party never started leaving")
	# Can't assert GONE_HOME state because the wait time on wait_for_signal, party is already deleted before being able to check
	#assert_eq(spawned_party.state, CustomerParty.PartyState.GONE_HOME, "Party is not gone")
	
	assert_eq(len(_customer_manager.parties), 0, "Customer Manager didn't get cleaned up from the party leaving")
	assert_null(spawned_party, "Party never got deleted after leaving")

func test_party_can_wait_in_line():
	# Arrange
	var num_customers_to_spawn = 4
	_customer_manager.max_parties = 2
	_restaurant.tables = []
	
	# Act
	var table_wait_party = _spawn_test_party(num_customers_to_spawn)
	await wait_for_signal(table_wait_party.state_changed, 1.3, "The first party took too long to get to the Entry")
	assert_eq(table_wait_party.state, CustomerParty.PartyState.WALKING_TO_ENTRY, "The first Party is not walking to the entry")
	
	await wait_for_signal(table_wait_party.state_changed, 1.3, "The first party took too long to get to the Entry")
	assert_eq(table_wait_party.state, CustomerParty.PartyState.WAITING_FOR_TABLE, "The first Party is not waiting for a table")
	
	# Act
	var line_wait_party = _spawn_test_party(num_customers_to_spawn)
	await wait_for_signal(line_wait_party.state_changed, 1.3, "The second party took too long to walk to the line")
	assert_eq(line_wait_party.state, CustomerParty.PartyState.WALKING_TO_LINE, "The second Party is not walking to the line")
	
	await wait_for_signal(line_wait_party.state_changed, 1.3, "The second party took too long to get to the line")
	assert_eq(line_wait_party.state, CustomerParty.PartyState.WAITING_IN_LINE, "The second Party is not waiting in line")
	
	# Assert
	assert_eq(len(_customer_manager.parties), 2, "There are not the correct number of parties")

func test_party_loses_patience_and_leaves():
	# Arrange
	var num_customers_to_spawn = 4
	_customer_manager.max_parties = 1
	
	# This test customer party HATES carbs
	var menu_item = _set_test_menu_to([NetworkedIds.Scene.PATTY, NetworkedIds.Scene.TOMATO])
	
	# Act
	var party = _spawn_test_party(num_customers_to_spawn)
	
	await _wait_for_party_to_reach(party, CustomerParty.PartyState.ORDERING)
	assert_eq(party.state, CustomerParty.PartyState.ORDERING)
	
