extends Node3D
class_name Table

signal occupied
signal available

@export var chairs : Array[Chair] = []

var is_empty = true

func _ready():
	if chairs.is_empty():
		for child in get_children():
			if child is Chair:
				chairs.push_back(child)

func table_can_hold_party(party_size : int) -> bool:
	if party_size > len(chairs) or not is_empty:
		return false
		
	for chair in chairs:
		if chair.sitter != null:
			return false
	return true

func seat_customers(customers: Array[Node3D]) -> bool:
	if not table_can_hold_party(len(customers)):
		return false
	
	var chair_index = 0
	for customer in customers:
		chairs[chair_index].sit(customer)
		chair_index += 1
	
	is_empty = false
	occupied.emit()
	return true

func release_customers():
	for chair in chairs:
		chair.force_sitter_out()
	is_empty = true
	available.emit()
