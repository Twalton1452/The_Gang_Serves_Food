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
	WAITING_IN_LINE = 2,
	
	WALKING_TO_ENTRY = 3,
	WAITING_FOR_TABLE = 4,
	WALKING_TO_TABLE = 5,
	
	THINKING = 6,
	ORDERING = 7,
	
	WAITING_FOR_FOOD = 8,
	EATING = 9,
	
	PAYING = 10,
	LEAVING = 11,
}

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
	
	# Node tree's resolve bottom to top, so when we're syncing to maintain the same order as the server,
	# Assign back-to-front : The first node sync'd needs to be the last one in the array
	var i = customers.rfind(null)
	customers[i] = customer
	
	# When we've reached the beginning of the array we've finished the sync for customers
	if i == 0:
		NetworkingUtils.sort_array_by_net_id(customers)
		
		if table and state > PartyState.WALKING_TO_TABLE:
			sit_at_table()

func set_state(value: PartyState) -> void:
	state = value
	state_changed.emit(self)

func set_customers(value: Array[Customer]) -> void:
	if not customers.is_empty():
		print("Tried to set_customers for party %s when it already has customers" % name)
		return
	
	customers = value
	var spacing = 0
	for customer in customers:
		customer.arrived.connect(_on_customer_arrived)
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
	
	for i in len(customers):
		var customer : Customer = customers[i]
		var chair : Chair = table.chairs[i]
		customer.go_to(chair.transition_location.global_position)
	
	state = PartyState.WALKING_TO_TABLE

# TODO: Customers try to sit in the farthest -> closest chair
func sit_at_table():
	for i in len(customers):
		var customer : Customer = customers[i]
		customer.disable_physics()
		var chair : Chair = table.chairs[i]
		chair.sit(customer)
		
	state = PartyState.THINKING

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
		PartyState.WALKING_TO_TABLE:
			sit_at_table()
		PartyState.ORDERING:
			pass
		PartyState.WAITING_FOR_FOOD:
			pass
		PartyState.EATING:
			pass
		PartyState.PAYING:
			pass
		PartyState.LEAVING:
			pass
