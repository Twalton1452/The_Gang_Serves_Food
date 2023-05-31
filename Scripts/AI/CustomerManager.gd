extends Node3D
class_name CustomerManager

@export var max_parties = 10

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
	restaurant.menu.new_menu.connect(_on_new_restaurant_menu_available)
	restaurant.table_became_available.connect(_on_table_became_available)

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
	if GameState.state != GameState.Phase.OPEN_FOR_BUSINESS:
		return
	
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
	new_party.advance_state.connect(_on_advance_party_state)
	add_child(new_party, true)
	new_party.position = Vector3.ZERO
	
	var party_members : Array[Customer] = []
	for i in range(party_size):
		party_members.push_back(customer_scene.instantiate() as Customer)
	
	new_party.customers = party_members
	
	if len(parties) > 0 and parties[-1].state <= CustomerParty.PartyState.WAITING_FOR_TABLE:
		new_party.wait_in_line(parties[-1])
	else:
		new_party.go_to_entry(restaurant.entry_point)
	parties.push_back(new_party)

func _on_table_became_available(table: Table):
	for i in len(parties):
		var party = parties[i]
		if party.state == CustomerParty.PartyState.WAITING_FOR_TABLE:
			party.go_to_table(table)
			move_the_line.call_deferred()
			break

func check_for_available_table_for(party: CustomerParty):
	var table = restaurant.get_next_available_table_for(party)
	
	if table == null:
		return
	
	party.go_to_table(table)
	move_the_line.call_deferred()

func move_the_line():
	var sent_a_party_to_door = false
	for i in len(parties):
		var party = parties[i]
		if party.state <= CustomerParty.PartyState.WAITING_FOR_TABLE:
			if not sent_a_party_to_door:
				sent_a_party_to_door = true
				party.go_to_entry(restaurant.entry_point)
			else:
				party.wait_in_line(parties[i-1])

func _on_new_restaurant_menu_available(menu: Menu) -> void:
	if menu == null:
		return
	
	for i in len(parties):
		var party = parties[i]
		if party.state == CustomerParty.PartyState.THINKING:
			draft_order_for(party)

func draft_order_for(party: CustomerParty):
	if not restaurant.menu.is_menu_available() or not is_multiplayer_authority():
		return
	party.order_from(restaurant.menu)
	
	var party_index = parties.find(party)
	var writer = ByteWriter.new()
	for customer in party.customers:
		writer.write_int_array(customer.order as Array[int])
	
	notify_peers_of_order.rpc(party_index, writer.data)

@rpc("authority")
func notify_peers_of_order(party_index: int, order_data: PackedByteArray):
	var reader = ByteReader.new(order_data)
	var party : CustomerParty = parties[party_index]
	for customer in party.customers:
		customer.order = reader.read_int_array() as Array[SceneIds.SCENES]
	party.state = CustomerParty.PartyState.ORDERING

func send_customers_home(party: CustomerParty) -> void:
	party.go_home(restaurant.entry_point, restaurant.exit_point)

func clean_up_party(party: CustomerParty) -> void:
	var i = parties.find(party)
	if i == -1:
		print_debug("Couldn't find party to delete")
		return
	parties.remove_at(i)
	NetworkingUtils.send_item_for_deletion(party)

func _on_party_state_changed(party: CustomerParty):
	match party.state:
		CustomerParty.PartyState.WAITING_FOR_TABLE:
			check_for_available_table_for(party)
		CustomerParty.PartyState.THINKING:
			draft_order_for(party)
		CustomerParty.PartyState.LEAVING_FOR_HOME:
			send_customers_home(party)
		CustomerParty.PartyState.GONE_HOME:
			clean_up_party(party)

func _on_advance_party_state(party: CustomerParty):
	notify_advance_party_state.rpc(StringName(party.name).to_utf8_buffer())
	
@rpc("authority", "call_local")
func notify_advance_party_state(node_name: PackedByteArray):
	var party : CustomerParty = get_node_or_null(node_name.get_string_from_utf8())
	if party == null:
		return
	
	#print("Advancing state because %s sent a message %s" % [multiplayer.get_remote_sender_id(), multiplayer.get_unique_id()])
	match party.state:
		CustomerParty.PartyState.WALKING_TO_LINE:
			party.state = CustomerParty.PartyState.WAITING_IN_LINE
		CustomerParty.PartyState.WALKING_TO_ENTRY:
			party.state = CustomerParty.PartyState.WAITING_FOR_TABLE
		CustomerParty.PartyState.WAITING_FOR_TABLE: pass # handled by _on_party_state_changed
		CustomerParty.PartyState.WALKING_TO_TABLE:
			party.sit_at_table()
		CustomerParty.PartyState.THINKING: pass # handled by _on_party_state_changed
		CustomerParty.PartyState.ORDERING:
			party.wait_for_food()
		CustomerParty.PartyState.WAITING_FOR_FOOD:
			party.eat_food()
		CustomerParty.PartyState.EATING:
			party.wait_to_pay()
		CustomerParty.PartyState.WAITING_TO_PAY:
			party.pay()
		CustomerParty.PartyState.PAYING: pass # just a wait phase for now
		CustomerParty.PartyState.LEAVING_FOR_HOME:
			party.state = CustomerParty.PartyState.GONE_HOME
		CustomerParty.PartyState.GONE_HOME: pass # handled by _on_party_state_changed
