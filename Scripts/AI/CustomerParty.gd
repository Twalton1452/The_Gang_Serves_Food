extends Node3D
class_name CustomerParty

## A group of customers makes up a CustomerParty
## This class will help to organize groups of Customers to tell them where to go like a family

signal state_changed(party: CustomerParty)

## The overall state of the Party, where they are at in the Lifecycle of the process
## does not represent individual customer emotions
enum PartyState {
	SPAWNING = 0,
	
	WAITING_IN_LINE = 1,
	WALKING_TO_ENTRY = 2,
	
	WAITING_FOR_TABLE = 3,
	WALKING_TO_TABLE = 4,
	
	THINKING = 5,
	ORDERING = 6,
	
	WAITING_FOR_FOOD = 7,
	EATING = 8,
	
	PAYING = 9,
	LEAVING = 10,
}

var state : PartyState = PartyState.SPAWNING : set = set_state
var customers : Array[Customer] = [] : set = set_customers
var customer_spacing = 0.5
var destination : Node3D = null
var table : Table = null
var num_arrived_to_destination = 0

var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.CUSTOMER_PARTY
var sync_state : PackedByteArray : set = set_sync_state, get = get_sync_state

func set_sync_state(value: PackedByteArray) -> void:
	pass

func get_sync_state() -> PackedByteArray:
	var buf = PackedByteArray()
	buf.resize(7)
	return buf

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

func wait_in_line(_party: CustomerParty) -> void:
	pass
	#state = PartyState.WAITING_IN_LINE

func go_to_entry(target: Node3D = null):
	destination = target
	num_arrived_to_destination = 0
	
	if destination != null:
		var spacing = 0.0
		for customer in customers:
			customer.go_to(destination.position + Vector3(0,0,-spacing))
			spacing += customer_spacing
	
	state = PartyState.WALKING_TO_ENTRY

func go_to_table(destination_table: Table):
	num_arrived_to_destination = 0
	table = destination_table
	
	for i in len(customers):
		var customer : Customer = customers[i]
		var chair : Chair = table.chairs[i]
		customer.go_to(chair.transition_location.global_position)
	
	state = PartyState.WALKING_TO_TABLE

func sit_at_table():
	for i in len(customers):
		var customer : Customer = customers[i]
		var chair : Chair = table.chairs[i]
		chair.sit(customer)
		
	state = PartyState.THINKING

func _on_customer_arrived():
	num_arrived_to_destination += 1
	
	if num_arrived_to_destination >= len(customers):
		advance_party_state()

func advance_party_state():
	match state:
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
