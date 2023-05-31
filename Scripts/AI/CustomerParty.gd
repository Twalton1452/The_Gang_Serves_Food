extends Node3D
class_name CustomerParty

## A group of customers makes up a CustomerParty
## This class will help to organize groups of Customers to tell them where to go like a family

signal state_changed(party: CustomerParty)

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
	LEAVING = 12, # Traveling to the kill zone
}

var think_time_sec = 2.0
var eating_time_sec = 2.0
var paying_time_sec = 2.0
var customer_spacing = 0.5
var customers : Array[Customer] = [] : set = set_customers
var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.CUSTOMER_PARTY

# Saved/Loaded State
var state : PartyState = PartyState.SPAWNING : set = set_state
var num_arrived_to_destination = 0
var table : Table = null
var target_pos : Vector3

func set_sync_state(reader: ByteReader) -> void:
	state = reader.read_int() as PartyState
	customers.resize(reader.read_int()) # fill arrays with null
	num_arrived_to_destination = reader.read_int()
	target_pos = reader.read_vector3()
	var has_table = reader.read_bool()
	if has_table:
		table = get_node(reader.read_path_to()) as Table
		table.is_empty = reader.read_bool()
		table.party_in_transit = reader.read_bool()
	(get_parent() as CustomerManager).sync_party(self)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_int(state)
	writer.write_int(customers.size())
	writer.write_int(num_arrived_to_destination)
	writer.write_vector3(target_pos)
	writer.write_bool(table != null)
	if table:
		writer.write_path_to(table)
		writer.write_bool(table.is_empty)
		writer.write_bool(table.party_in_transit)
	return writer

func sync_customer(customer: Customer) -> void:
	customer.arrived.connect(_on_customer_arrived)
	customer.player_interacted_with.connect(_on_customer_arrived)
	customer.got_order.connect(_on_customer_arrived)
	
	var i = customers.rfind(null)
	customers[i] = customer
	
	# When we've reached the beginning of the array we've finished the sync for customers
	if i == 0:
		NetworkingUtils.sort_array_by_net_id(customers)
		
		if table and state > PartyState.WALKING_TO_TABLE:
			sit_at_table()

func set_state(value: PartyState) -> void:
	state = value
	num_arrived_to_destination = 0
	emit_state_changed.call_deferred()

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
		
		customer.position = Vector3(0,0,-spacing)
		spacing += customer_spacing
		add_child(customer, true)

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
	num_arrived_to_destination = 0
	
	send_customers_to(entry.global_position)
	
	state = PartyState.WALKING_TO_ENTRY

func go_to_table(destination_table: Table):
	num_arrived_to_destination = 0
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
		customer.disable_physics()
		var chair : Chair = table.chairs[i]
		chair.sit(customer)
		
	state = PartyState.THINKING

func order_from(menu: Menu) -> void:
	await get_tree().create_timer(think_time_sec).timeout
	
	for customer in customers:
		customer.order_from(menu)
	
	state = PartyState.ORDERING

func eat_food() -> void:
	state = PartyState.EATING
	await get_tree().create_timer(eating_time_sec).timeout
		
	for customer in customers:
		customer.eat()
	
	state = PartyState.WAITING_TO_PAY

func pay() -> void:
	await get_tree().create_timer(paying_time_sec).timeout
	state = PartyState.LEAVING

func _on_customer_arrived():
	num_arrived_to_destination += 1
	if not is_multiplayer_authority():
		return
	
	
	if num_arrived_to_destination >= len(customers):
		advance_party_state.rpc()

@rpc("authority", "call_local")
func advance_party_state():
	#print("Advancing state because %s sent a message %s" % [multiplayer.get_remote_sender_id(), multiplayer.get_unique_id()])
	match state:
		PartyState.WALKING_TO_LINE:
			state = PartyState.WAITING_IN_LINE
		PartyState.WALKING_TO_ENTRY:
			state = PartyState.WAITING_FOR_TABLE
		PartyState.WAITING_FOR_TABLE: pass # handled by CustomerManager
		PartyState.WALKING_TO_TABLE:
			sit_at_table()
		PartyState.THINKING: pass # handled by CustomerManager
		PartyState.ORDERING:
			state = PartyState.WAITING_FOR_FOOD
		PartyState.WAITING_FOR_FOOD:
			eat_food()
		PartyState.EATING:
			state = PartyState.WAITING_TO_PAY
		PartyState.WAITING_TO_PAY:
			state = PartyState.PAYING
		PartyState.PAYING:
			pay()
		PartyState.LEAVING: pass # handled by CustomerManager
