extends Node3D
class_name CustomerManager

@export var max_parties = 10

@onready var restaurant : Restaurant = get_parent()

var customer_scene = preload("res://Scenes/customer.tscn")
var parties : Array[CustomerParty] = []
var max_party_size = 4

#func _ready():
#	spawn_party.call_deferred(4)

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("ui_page_up"):
		spawn_party(randi_range(1, max_party_size))

func spawn_party(party_size: int) -> void:
	if party_size > max_party_size:
		return
	
	var new_party = CustomerParty.new()
	new_party.state_changed.connect(_on_party_state_changed)
	new_party.name = "Party"
	add_child(new_party, true)
	new_party.position = Vector3.ZERO
	
	var party_members : Array[Customer] = []
	for i in range(party_size):
		party_members.push_back(customer_scene.instantiate() as Customer)
	
	new_party.customers = party_members
	parties.push_back(new_party)
	
	# TODO: When a Party is spawned and other Parties are waiting at the door
	# Set their destination to the last person in line instead of entry_point
	new_party.advance(restaurant.entry_point)

func evaluate_parties():
	for party in parties:
		_on_party_state_changed(party)

func _on_party_state_changed(party: CustomerParty):
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
			
	
