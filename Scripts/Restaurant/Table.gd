extends Node3D
class_name Table

signal occupied
signal available

var chairs : Array[Node3D] = []

var is_empty = true

func is_available_seat():
	return true

func seat_customer(customer: Node3D):
	pass

func seat_customers(customers: Array[Node3D]):
	pass

func get_up():
	pass
