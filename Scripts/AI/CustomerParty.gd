extends Node3D
class_name CustomerParty

## A group of customers makes up a CustomerParty
## This class will help to organize groups of Customers to tell them where to go like a family

signal state_changed(party: CustomerParty)
signal advance_state(party: CustomerParty)

## The overall state of the Party, where they are at in the Lifecycle of the process
## does not represent individual customer emotions
enum PartyState {
	SPAWNING = 0,
	
	WALKING_TO_LINE = 1,
	WAITING_IN_LINE = 2, # PATIENCE - Walking forward only when the party ahead walks forward
	
	WALKING_TO_ENTRY = 3, # First in line walking to the door
	WAITING_FOR_TABLE = 4, # PATIENCE - At the front door waiting to be told a table is ready
	WALKING_TO_TABLE = 5,
	
	THINKING = 6, # Wait Phase before transitioning to ordering for more realism
	ORDERING = 7, # PATIENCE - Waiting for player to take their order
	
	WAITING_FOR_FOOD = 8, # PATIENCE - Waiting for player to deliver food
	EATING = 9, # Wait Phase before transitioning to paying for more realism
	
	WAITING_TO_PAY = 10, # PATIENCE - Waiting for player to help them pay
	PAYING = 11, # Wait Phase before transitioning to leaving for more realism
	LEAVING_FOR_HOME = 12, # Traveling to the kill zone
	GONE_HOME = 13, # Traveling to the kill zone
}

var think_time_sec = 2.0
var eating_time_sec = 2.0
var paying_time_sec = 2.0
var wait_before_leave_time_sec = 1.0
var wait_between_customers_leaving = 0.2
var customer_spacing = 0.5
var customers : Array[Customer] = [] : set = set_customers
var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.CUSTOMER_PARTY
var required_interaction_states = [PartyState.ORDERING, PartyState.WAITING_TO_PAY]

# Saved/Loaded State
var state : PartyState = PartyState.SPAWNING : set = set_state
var num_arrived_to_destination = 0
var table : Table = null
var target_pos : Vector3
var num_customers_required_to_advance = 1

func set_sync_state(reader: ByteReader) -> void:
	state = reader.read_int() as PartyState
	customers.resize(reader.read_int()) # fill arrays with null
	num_arrived_to_destination = reader.read_int()
	num_customers_required_to_advance = reader.read_int()
	target_pos = reader.read_vector3()
	var has_table = reader.read_bool()
	if has_table:
		table = get_node(reader.read_path_to()) as Table
		table.is_empty = reader.read_bool()
		table.party_in_transit = reader.read_bool()
		table.color = reader.read_color()
	(get_parent() as CustomerManager).sync_party(self)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_int(state)
	writer.write_int(customers.size())
	writer.write_int(num_arrived_to_destination)
	writer.write_int(num_customers_required_to_advance)
	writer.write_vector3(target_pos)
	writer.write_bool(table != null)
	if table:
		writer.write_path_to(table)
		writer.write_bool(table.is_empty)
		writer.write_bool(table.party_in_transit)
		writer.write_color(table.color)
	return writer

func sync_customer(customer: Customer) -> void:
	customer.arrived.connect(_on_customer_arrived)
	customer.player_interacted_with.connect(_on_customer_arrived)
	customer.got_order.connect(_on_customer_arrived)
	customer.ate_food.connect(_on_customer_arrived)
	
	var i = customers.rfind(null)
	customers[i] = customer
	
	# When we've reached the beginning of the array we've finished the sync for customers
	if i == 0:
		NetworkingUtils.sort_array_by_net_id(customers)

func set_state(value: PartyState) -> void:
	state = value
	num_arrived_to_destination = 0
	num_customers_required_to_advance = len(customers)
	emit_state_changed.call_deferred()
	if table:
		if state in required_interaction_states:
			table.color = Color.GOLD
		else:
			table.color = Color.FOREST_GREEN
	#print("Party has advanced to state: %s" % str(state))

func emit_state_changed():
	state_changed.emit(self)

func set_customers(value: Array[Customer]) -> void:
	if not customers.is_empty():
		print("Tried to set_customers for party %s when it already has customers" % name)
		return
	
	customers = value
	var spacing = 0
	for customer in customers:
		customer.arrived.connect(_on_customer_arrived)
		customer.player_interacted_with.connect(_on_customer_arrived)
		customer.got_order.connect(_on_customer_arrived)
		customer.ate_food.connect(_on_customer_arrived)
		
		customer.position = Vector3(0,0,-spacing)
		spacing += customer_spacing
		add_child(customer, true)
	num_customers_required_to_advance = len(customers)

func send_customers_to(pos: Vector3) -> void:
	target_pos = pos
	
	var spacing = 0.0
	for customer in customers:
		customer.go_to(target_pos + Vector3(0,0,-spacing))
		spacing += customer_spacing

func wait_in_line(ahead_party: CustomerParty) -> void:
	state = PartyState.WALKING_TO_LINE
	# This is for single-file line, Z-axis spacing
	# Calculate the spacing for how many customers are in the ahead party
	# Then add a distance behind them
	# var spacing_behind_party = (len(ahead_party.customers) * customer_spacing) + customer_spacing
		
	send_customers_to(ahead_party.target_pos + Vector3(customer_spacing,0,0))

func go_to_entry(entry: Node3D):
	send_customers_to(entry.global_position)
	
	state = PartyState.WALKING_TO_ENTRY

func go_to_table(destination_table: Table):
	table = destination_table
	table.lock_for_party_in_transit()
	target_pos = table.global_position
	
	var available_chairs = table.chairs.duplicate()
	
	for i in len(customers):
		var customer : Customer = customers[i]
		var chair_index : int = get_farthest_chair_for(customer, available_chairs)
		var chair : Chair = available_chairs[chair_index]
		available_chairs.remove_at(chair_index)
		customer.go_to(chair.transition_location.global_position)
	
	state = PartyState.WALKING_TO_TABLE

## Seat customers at tables given their farthest chair to reduce potential collisions between them
func get_farthest_chair_for(customer: Customer, chairs: Array[Chair]) -> int:
	var dist = 0.0
	var greatest_dist_index = -1
	
	for i in len(chairs):
		var chair : Chair = chairs[i]
		var customer_chair_dist = chair.global_position.distance_to(customer.global_position)
		if customer_chair_dist > dist:
			dist = customer_chair_dist
			greatest_dist_index = i
	
	return greatest_dist_index

func sit_at_table():
	for i in len(customers):
		var customer : Customer = customers[i]
		var chair : Chair = table.chairs[i]
		chair.sit(customer)
		
	state = PartyState.THINKING


func order_from(menu: Menu) -> void:
	await get_tree().create_timer(think_time_sec).timeout
	
	for customer in customers:
		customer.order_from(menu)
	
	state = PartyState.ORDERING
	num_customers_required_to_advance = 1

func wait_for_food():
	state = CustomerParty.PartyState.WAITING_FOR_FOOD
	for customer in customers:
		customer.interactable.disable_collider()
		customer.evaluate_food()

func eat_food() -> void:
	state = PartyState.EATING
	await get_tree().create_timer(eating_time_sec).timeout
		
	for customer in customers:
		customer.eat()

func wait_to_pay() -> void:
	for customer in customers:
		customer.interactable.enable_collider()
	
	state = CustomerParty.PartyState.WAITING_TO_PAY
	num_customers_required_to_advance = 1

func pay() -> void:
	state = PartyState.PAYING
	await get_tree().create_timer(paying_time_sec).timeout
	
	# TODO: GIVE THE PLAYERS MONEYYYYY
	
	state = PartyState.LEAVING_FOR_HOME
	num_customers_required_to_advance = 1

func go_home(entry_point: Node3D, exit_point: Node3D) -> void:
	table.release_customers()
	table = null
	target_pos = exit_point.global_position
	await get_tree().create_timer(wait_before_leave_time_sec).timeout
	
	var customers_ordered_by_closest_to_door = customers.duplicate()
	customers_ordered_by_closest_to_door.sort_custom(func(a: Customer, b: Customer):
		if b.global_position.distance_to(entry_point.global_position) < a.global_position.distance_to(entry_point.global_position):
			return true
		return false
	)
	for customer in customers_ordered_by_closest_to_door:
		await get_tree().create_timer(wait_between_customers_leaving).timeout
		customer.go_to(exit_point.global_position)

func _on_customer_arrived():
	num_arrived_to_destination += 1
	if not is_multiplayer_authority():
		return
	
	if num_arrived_to_destination >= num_customers_required_to_advance:
		#advance_party_state.rpc()
		advance_state.emit(self)
