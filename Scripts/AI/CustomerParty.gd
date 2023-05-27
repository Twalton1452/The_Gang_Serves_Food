extends Node3D
class_name CustomerParty

## A group of customers makes up a CustomerParty
## This class will help to organize groups of Customers to tell them where to go like a family

signal state_changed

## The overall state of the Party, where they are at in the Lifecycle of the process
## does not represent individual customer emotions
enum PartyState {
	SPAWNING,
	WALKING_TO_ENTRY,
	
	WAITING_FOR_TABLE,
	WALKING_TO_TABLE,
	
	THINKING,
	ORDERING,
	
	WAITING_FOR_FOOD,
	EATING,
	
	PAYING,
	LEAVING
}

var state : PartyState = PartyState.SPAWNING
var customers : Array[Customer] = [] : set = set_customers
var customer_spacing = 0.5
var destination : Node3D = null
var num_arrived_to_destination = 0

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

func advance(target: Node3D = null):
	destination = target
	
	if destination != null:
		var spacing = 0.0
		for customer in customers:
			customer.go_to(destination.position + Vector3(0,0,-spacing))
			spacing += customer_spacing
	
	@warning_ignore("int_as_enum_without_cast")
	state += 1

func _on_customer_arrived():
	num_arrived_to_destination += 1
	
	if num_arrived_to_destination >= len(customers):
		@warning_ignore("int_as_enum_without_cast")
		state += 1
		state_changed.emit(self)
