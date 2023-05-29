extends Node3D
class_name CustomerManager

@export var max_parties = 5

@onready var restaurant : Restaurant = get_parent()

var customer_scene = preload("res://Scenes/customer.tscn")
var party_scene = preload("res://Scenes/components/party.tscn")
var parties : Array[CustomerParty] = []
var min_party_size = 1
var max_party_size = 4
var min_wait_to_spawn_sec = 3.0
var max_wait_to_spawn_sec = 15.0

func _ready():
	if not is_multiplayer_authority():
		return
	
	start_customer_spawning()

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	
	if event.is_action_pressed("ui_page_up"):
		#spawn_party.rpc(randi_range(min_wait_to_spawn_sec, max_party_size))
		spawn_party.rpc(4)

func sync_party(party: CustomerParty):
	party.state_changed.connect(_on_party_state_changed)
	parties.push_back(party)
	NetworkingUtils.sort_array_by_net_id(parties)

func start_customer_spawning():
	await get_tree().create_timer(randf_range(min_wait_to_spawn_sec, max_wait_to_spawn_sec)).timeout
	spawn_party.rpc(randi_range(min_party_size, max_party_size))
	if len(parties) < max_parties:
		start_customer_spawning()

@rpc("authority", "call_local")
func spawn_party(party_size: int) -> void:
	if party_size > max_party_size:
		return
	
	var new_party : CustomerParty = party_scene.instantiate()
	new_party.state_changed.connect(_on_party_state_changed)
	add_child(new_party, true)
	new_party.position = Vector3.ZERO
	
	var party_members : Array[Customer] = []
	for i in range(party_size):
		party_members.push_back(customer_scene.instantiate() as Customer)
	
	new_party.customers = party_members
	
	# TODO: When a Party is spawned and other Parties are waiting at the door
	# Set their destination to the last person in line instead of entry_point
	if len(parties) > 0 and parties[-1].state <= CustomerParty.PartyState.WAITING_FOR_TABLE:
		new_party.wait_in_line(parties[-1])
	else:
		new_party.go_to_entry(restaurant.entry_point)
	parties.push_back(new_party)

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
	move_the_line.call_deferred()

func move_the_line():
	#var in_line_parties = parties.filter(func(p): return p.state == CustomerParty.PartyState.WAITING_IN_LINE)
	#for i in len(in_line_parties):
	var sent_a_party_to_door = false
	for i in len(parties):
		var party = parties[i]
		if party.state <= CustomerParty.PartyState.WAITING_FOR_TABLE:
			if not sent_a_party_to_door:
				sent_a_party_to_door = true
				party.go_to_entry(restaurant.entry_point)
			else:
				party.wait_in_line(parties[i-1])
	
