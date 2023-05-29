extends Node3D
class_name CustomerManager

@export var max_parties = 10

@onready var restaurant : Restaurant = get_parent()

var customer_scene = preload("res://Scenes/customer.tscn")
var party_scene = preload("res://Scenes/components/party.tscn")
var parties : Array[CustomerParty] = []
var max_party_size = 4

#func _ready():
#	spawn_party.call_deferred(4)

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("ui_page_up"):
		#spawn_party(randi_range(1, max_party_size))
		spawn_party(4)

func sync_party(party: CustomerParty):
	party.state_changed.connect(_on_party_state_changed)

func spawn_party(party_size: int) -> void:
	if party_size > max_party_size:
		return
	
	var new_party = party_scene.instantiate()
	new_party.state_changed.connect(_on_party_state_changed)
	add_child(new_party, true)
	new_party.position = Vector3.ZERO
	
	var party_members : Array[Customer] = []
	for i in range(party_size):
		party_members.push_back(customer_scene.instantiate() as Customer)
	
	new_party.customers = party_members
	parties.push_back(new_party)
	
	# TODO: When a Party is spawned and other Parties are waiting at the door
	# Set their destination to the last person in line instead of entry_point
	if len(parties) > 1 and parties[-1].state <= CustomerParty.PartyState.WAITING_FOR_TABLE:
		new_party.wait_in_line(parties[-1])
	else:
		new_party.go_to_entry(restaurant.entry_point)

func _on_party_state_changed(party: CustomerParty):
	match party.state:
		CustomerParty.PartyState.WAITING_FOR_TABLE:
			check_for_available_table_for(party)
		CustomerParty.PartyState.LEAVING:
			pass

func check_for_available_table_for(party: CustomerParty):
	var table = restaurant.get_next_available_table_for(party)
	# No table's are available yet
	# They will have to wait for existing parties to leave
	if table == null:
		return
	
	party.go_to_table(table)
