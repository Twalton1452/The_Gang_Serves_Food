extends Node3D
class_name CustomerManager

@export var max_parties = 10

@onready var restaurant : Restaurant = get_parent()

var customer_scene = preload("res://Scenes/customer.tscn")
var parties : Array[CustomerParty] = []

#func _ready():
#	spawn_party.call_deferred(4)

func spawn_party(party_size: int) -> void:
	var new_party = CustomerParty.new()
	new_party.name = "Party"
	add_child(new_party, true)
	new_party.position = Vector3.ZERO
	
	var party_members : Array[Customer] = []
	for i in range(party_size):
		party_members.push_back(customer_scene.instantiate() as Customer)
	
	new_party.customers = party_members
	parties.push_back(new_party)
	
	new_party.advance(restaurant.entry_point)

func evaluate_parties():
	for party in parties:
		evaluate_party(party)

func evaluate_party(party: CustomerParty):
	match party.state:
		CustomerParty.PartyState.SPAWNING:
			pass
		CustomerParty.PartyState.WALKING_TO_ENTRY:
			pass
		CustomerParty.PartyState.WAITING_FOR_TABLE:
			pass
		CustomerParty.PartyState.WALKING_TO_TABLE:
			pass
		CustomerParty.PartyState.ORDERING:
			pass
		CustomerParty.PartyState.WAITING_FOR_FOOD:
			pass
		CustomerParty.PartyState.EATING:
			pass
		CustomerParty.PartyState.PAYING:
			pass
		CustomerParty.PartyState.LEAVING:
			pass
			
	
