extends TestingUtils

var RestaurantScene = load("res://test/Scenes/test_restaurant.tscn")

var _restaurant : Restaurant = null
var _table : Table = null
var _customer_manager : CustomerManager = null
var _acceptable_threshold = Vector3(.3, .3, .3)

func _assert_all_child_interactables_not_on_interactable_layer(node: Node) -> void:
	for child in node.get_children():
		if child is Interactable:
			assert_eq(child.get_collision_layer_value(3), false)
		_assert_all_child_interactables_not_on_interactable_layer(child)

func _wait_for_party_to_reach(party: CustomerParty, state: CustomerParty.PartyState):
	for i in range(party.state, state + 1):
		if party.state == state or party.state > state:
			return
		await wait_for_signal(party.state_changed, 1.0, "The party took too long to get to the desired state")

func _spawn_test_party(num_customers: int) -> CustomerParty:
	GameState.modifiers.max_party_size = num_customers
	_customer_manager.spawn_party(num_customers)
	var spawned_party = _customer_manager.parties[-1]
	spawned_party.think_time_sec = 0.05
	spawned_party.eating_time_sec = 0.05
	spawned_party.paying_time_sec = 0.05
	spawned_party.wait_before_leave_time_sec = 0.05
	spawned_party.wait_between_customers_leaving = 0.05
	for customer in spawned_party.customers:
		watch_signals(customer)
		customer.speed = 10.0
	return spawned_party

func _set_test_menu_to(dish: Array[NetworkedIds.Scene]) -> Node3D:
	var menu_item_dish = create_combined_food(dish)
	#var dummy_net_node = double(NetworkedNode3D, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	var dummy_net_node = NetworkedNode3D.new()
	dummy_net_node.name = "NetworkedNode3D"
	autoqfree(dummy_net_node)
	menu_item_dish.add_child(dummy_net_node)
	
	_restaurant.menu.menu_items[0].dish_display_holder.hold_item(menu_item_dish)
	return menu_item_dish

func before_each():
	_restaurant = RestaurantScene.instantiate()
	add_child_autoqfree(_restaurant)
	_table = _restaurant.tables[0]
	_customer_manager = _restaurant.get_node("CustomerManager")
	_customer_manager.restaurant = _restaurant
	_customer_manager.max_parties = 0
	_customer_manager.min_wait_to_spawn_sec = 998
	_customer_manager.max_wait_to_spawn_sec = 999
	#watch_signals(_customer_manager)

func test_party_full_journey():
	GameState.modifiers = load("res://test/Testing_Modifiers.tres")
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
		assert_eq(customer.order.is_equal_to(menu_item_dish), true)
		assert_not_null(customer.order.display_order, "There is no visual for the customer's order")
		assert_almost_eq(customer.order.global_position, customer.sitting_chair.holder.global_position, Vector3(0.2, 0.2, 0.2))
		assert_eq(customer.order.visible, false, "The order visual is showing too early")
		assert_eq(customer.interactable.is_collider_enabled(), true, "Customer isn't interactable when they should be")
	
	spawned_party.customers[0]._on_player_interacted() # pretend the player interacted with a customer
	
	for customer in spawned_party.customers:
		assert_eq(customer.interactable.is_collider_enabled(), false, "Customer is interactable when they shouldn't be")
		assert_eq(customer.order.visible, true, "The order visual isn't showing")
		_assert_all_child_interactables_not_on_interactable_layer(customer.order)
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "The party didn't order")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_FOR_FOOD, "Party isn't waiting for their food")
	
	for chair in _restaurant.tables[0].chairs:
		chair.holder.hold_item(menu_item_dish.duplicate())
		chair.holder.interacted.emit() # pretend the player put the item down
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Party never got their food")
	assert_eq(spawned_party.state, CustomerParty.PartyState.EATING, "Party is not eating")
	
	for customer in spawned_party.customers:
		assert_eq(customer.order.visible, false, "The order visual is still showing after being given food")
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Party never ate their food")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_TO_PAY, "Party is not waiting to pay")
	assert_eq(spawned_party.num_customers_required_to_advance, 1, "Player should only need to talk to 1 customer to initiate paying")
	var player_interactions = 0
	for customer in spawned_party.customers:
		player_interactions += get_signal_emit_count(customer, "player_interacted_with")
		assert_signal_emit_count(customer, "got_order", 1)
		assert_signal_emit_count(customer, "ate_food", 1)
		assert_eq(customer.interactable.is_collider_enabled(), true, "Customer isn't interactable when they should be")
	assert_eq(player_interactions, 1, "Customers were not interacted with the expected number of times")
	
	for chair in _restaurant.tables[0].chairs:
		assert_eq(chair.holder.is_holding_item(), true, "There isn't something left on the table")
		assert_eq(chair.holder.get_held_item().SCENE_ID, NetworkedIds.Scene.FOOD_DIRT, "There isn't dirt on the table")
	
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
	

func test_party_can_wait_in_line_then_sit():
	# Arrange
	var num_customers_to_spawn = 4
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
	
	_restaurant.tables = [_table]
	_restaurant.table_became_available.emit(_table)
	
	await wait_for_signal(table_wait_party.state_changed, 1.3, "The party took too long to walk to the table")
	assert_eq(table_wait_party.state, CustomerParty.PartyState.WALKING_TO_TABLE, "The is not walking to the line")
	await wait_for_signal(table_wait_party.state_changed, 1.3, "The party took too long to sit")
	assert_eq(table_wait_party.state, CustomerParty.PartyState.THINKING, "The party is not sitting at the table")
	assert_eq(line_wait_party.state, CustomerParty.PartyState.WAITING_FOR_TABLE, "The waiting party is not waiting for a table")
	
	_customer_manager.send_customers_home(table_wait_party)
	table_wait_party.state = CustomerParty.PartyState.LEAVING_FOR_HOME
	await wait_frames(1)
	assert_eq(line_wait_party.state, CustomerParty.PartyState.WALKING_TO_TABLE, "The waiting party is not walking to the table")

func test_party_loses_patience_and_leaves_during_ordering():
	# Arrange
	var num_customers_to_spawn = 4
	
	# This test customer party HATES carbs - No buns! :)
	_set_test_menu_to([NetworkedIds.Scene.PATTY, NetworkedIds.Scene.TOMATO])
	
	var spawned_party = _spawn_test_party(num_customers_to_spawn)
	await _wait_for_party_to_reach(spawned_party, CustomerParty.PartyState.ORDERING)
	assert_eq(spawned_party.state, CustomerParty.PartyState.ORDERING)
	
	# Act
	spawned_party.patience = -spawned_party.patience_states[spawned_party.state].rate
	NetworkedPartyManager._on_patience_tick()
	await wait_for_signal(spawned_party.state_changed, 1.0, "Customers didn't leave impatient")
	
	# Assert
	assert_eq(spawned_party.state, CustomerParty.PartyState.LEAVING_FOR_HOME_IMPATIENT)
	assert_null(spawned_party.table)
	
	for customer in spawned_party.customers as Array[Customer]:
		assert_eq(customer.order.visible, false)
	
	await wait_for_signal(spawned_party.state_changed, 2.0, "Party never left")
	
	assert_eq(len(_customer_manager.parties), 0, "Customer Manager didn't get cleaned up from the party leaving")
	assert_null(spawned_party, "Party never got deleted after leaving")

func test_party_loses_patience_and_leaves_during_thinking_with_no_menu():
	# Arrange
	var num_customers_to_spawn = 4
	
	var spawned_party = _spawn_test_party(num_customers_to_spawn)
	await _wait_for_party_to_reach(spawned_party, CustomerParty.PartyState.THINKING)
	assert_eq(spawned_party.state, CustomerParty.PartyState.THINKING)
	
	# Act
	spawned_party.patience = -spawned_party.patience_states[spawned_party.state].rate
	NetworkedPartyManager._on_patience_tick()
	await wait_for_signal(spawned_party.state_changed, 1.0, "Customers didn't leave impatient")
	
	# Assert
	assert_eq(spawned_party.state, CustomerParty.PartyState.LEAVING_FOR_HOME_IMPATIENT)
	assert_null(spawned_party.table)
	
	for customer in spawned_party.customers as Array[Customer]:
		assert_null(customer.order)
	
	await wait_for_signal(spawned_party.state_changed, 2.0, "Party never left")
	
	assert_eq(len(_customer_manager.parties), 0, "Customer Manager didn't get cleaned up from the party leaving")
	assert_null(spawned_party, "Party never got deleted after leaving")

func test_party_loses_patience_and_leaves_during_waiting_to_pay():
	# Arrange
	var num_customers_to_spawn = 4
	
	# Carbs only
	var menu_item_dish = _set_test_menu_to([NetworkedIds.Scene.BOTTOM_BUN, NetworkedIds.Scene.TOP_BUN])
	
	var spawned_party = _spawn_test_party(num_customers_to_spawn)
	await _wait_for_party_to_reach(spawned_party, CustomerParty.PartyState.ORDERING)
	assert_eq(spawned_party.state, CustomerParty.PartyState.ORDERING)
	
	(spawned_party.customers[0] as Customer)._on_player_interacted()
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Customers didn't leave impatient")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_FOR_FOOD)
	
	for chair in _restaurant.tables[0].chairs:
		chair.holder.hold_item(menu_item_dish.duplicate())
		chair.holder.interacted.emit() # pretend the player put the item down
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Customers didn't eat")
	assert_eq(spawned_party.state, CustomerParty.PartyState.EATING)
	
	await wait_for_signal(spawned_party.state_changed, 1.0, "Customers didn't finish eating")
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_TO_PAY)
	
	# Act
	spawned_party.patience = -spawned_party.patience_states[spawned_party.state].rate
	NetworkedPartyManager._on_patience_tick()
	await wait_for_signal(spawned_party.state_changed, 1.0, "Customers didn't leave impatient")
	
	# Assert
	assert_eq(spawned_party.state, CustomerParty.PartyState.LEAVING_FOR_HOME_IMPATIENT)
	assert_null(spawned_party.table)
	
	for customer in spawned_party.customers as Array[Customer]:
		assert_eq(customer.order.visible, false)
	
	await wait_for_signal(spawned_party.state_changed, 2.0, "Party never left")
	
	assert_eq(len(_customer_manager.parties), 0, "Customer Manager didn't get cleaned up from the party leaving")
	assert_null(spawned_party, "Party never got deleted after leaving")
	
func test_party_loses_patience_and_leaves_during_waiting_for_table():
	# Arrange
	var num_customers_to_spawn = 4
	_restaurant.tables = []
	
	var spawned_party = _spawn_test_party(num_customers_to_spawn)
	await _wait_for_party_to_reach(spawned_party, CustomerParty.PartyState.WAITING_FOR_TABLE)
	assert_eq(spawned_party.state, CustomerParty.PartyState.WAITING_FOR_TABLE)
	
	# Act
	spawned_party.patience = -spawned_party.patience_states[spawned_party.state].rate
	NetworkedPartyManager._on_patience_tick()
	await wait_for_signal(spawned_party.state_changed, 1.0, "Customers didn't leave impatient")
	
	# Assert
	assert_eq(spawned_party.state, CustomerParty.PartyState.LEAVING_FOR_HOME_IMPATIENT)
	assert_null(spawned_party.table)
	
	for customer in spawned_party.customers as Array[Customer]:
		assert_null(customer.order)
	
	await wait_for_signal(spawned_party.state_changed, 2.0, "Party never left")
	
	assert_eq(len(_customer_manager.parties), 0, "Customer Manager didn't get cleaned up from the party leaving")
	assert_null(spawned_party, "Party never got deleted after leaving")
