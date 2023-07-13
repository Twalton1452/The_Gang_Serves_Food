extends Node3D
class_name CustomerManager

@export var max_parties = 1
@export var min_wait_to_spawn_sec = 1.0
@export var max_wait_to_spawn_sec = 1.0

@onready var restaurant : Restaurant = get_parent()

var customer_scene = preload("res://Scenes/customer.tscn")
var party_scene = preload("res://Scenes/components/party.tscn")
var parties : Array[CustomerParty] = []
var can_spawn = true
var is_spawning = true

func _enter_tree() -> void:
	child_entered_tree.connect(_on_child_entered_tree)

func _ready():
	restaurant.table_became_available.connect(_on_table_became_available)
	restaurant.menu.new_menu.connect(_on_new_restaurant_menu_available)
	GameState.state_changed.connect(_on_game_state_changed)
	_on_game_state_changed()
	
	start_customer_spawning()

func _on_game_state_changed() -> void:
	if GameState.state == GameState.Phase.OPEN_FOR_BUSINESS:
		can_spawn = true
		is_spawning = true
		start_customer_spawning()
	else:
		can_spawn = false
		is_spawning = false
		for party in parties:
			party.state = CustomerParty.PartyState.LEAVING_FOR_HOME

func _on_child_entered_tree(customer_party: Node) -> void:
	if not customer_party is CustomerParty:
		return
	
	customer_party.state_changed.connect(_on_party_state_changed)
	customer_party.has_expected_customers.connect(_on_party_has_expected_customers)
	customer_party.global_position = restaurant.customer_spawn_point.global_position
	
	parties.push_back(customer_party)

func _on_party_has_expected_customers(party: CustomerParty) -> void:
	# Find the last party to wait behind, if none exist go to entry
	if len(parties) > 0:
		var i = parties.size() - 1
	
		while i >= 0:
			if parties[i] == party:
				i -= 1
				continue
			
			if parties[i].state <= CustomerParty.PartyState.WAITING_FOR_TABLE:
				party.wait_in_line(parties[i])
				return
			
			i -= 1
	
	party.go_to_entry(restaurant.entry_point)

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	
	if event.is_action_pressed("ui_page_up"):
		#spawn_party.rpc(randi_range(min_wait_to_spawn_sec, max_party_size))
		spawn_party.rpc(4)

## Called from CustomerParty when they have Spawned
func sync_party(party: CustomerParty):
	NetworkingUtils.sort_array_by_net_id(parties)

func start_customer_spawning():
	if not is_multiplayer_authority():
		return
	
	if not can_spawn or not is_spawning:
		return
	
	await get_tree().create_timer(randf_range(min_wait_to_spawn_sec, max_wait_to_spawn_sec), false).timeout
	
	# State may have changed between waits
	if not can_spawn or not is_spawning:
		return
	
	if len(parties) < max_parties:
		spawn_party(randi_range(GameState.modifiers.min_party_size, GameState.modifiers.max_party_size))
		start_customer_spawning()
	else:
		is_spawning = false

func spawn_party(party_size: int) -> void:
	if party_size > GameState.modifiers.max_party_size:
		return
	
	var new_party : CustomerParty = NetworkingUtils.spawn_node_for_everyone(party_scene, self)
	new_party.party_size = party_size
	
	var writer = ByteWriter.new()
	writer.write_str(new_party.name)
	writer.write_int(party_size)
	notify_peers_of_spawned_party.rpc(writer.data)
	
	for i in range(party_size):
		NetworkingUtils.spawn_node_for_everyone(customer_scene, new_party)

@rpc("authority", "call_remote")
func notify_peers_of_spawned_party(data: PackedByteArray) -> void:
	var reader = ByteReader.new(data)
	var spawned_party = get_node(reader.read_str())
	spawned_party.party_size = reader.read_int()

func _on_table_became_available(_table: Table) -> void:
	# Prioritize the parties at the front of the line that are waiting for a table
	# If they cant find a table then allow those behind them to search for a table
	for party in parties:
		if party == null or party.is_queued_for_deletion():
			continue
		
		if party.state == CustomerParty.PartyState.WAITING_FOR_TABLE:
			if check_for_available_table_for(party):
				return
	
	for party in parties:
		if party == null or party.is_queued_for_deletion():
			continue
	
		if party.state == CustomerParty.PartyState.WAITING_IN_LINE:
			if check_for_available_table_for(party):
				return

func check_for_available_table_for(party: CustomerParty) -> bool:
	var table = restaurant.get_next_available_table_for(party)
	
	if table == null:
		party.wait_for_table(restaurant.entry_point)
		return false
	
	party.go_to_table(table)
	move_the_line.call_deferred()
	return true

func move_the_line():
	var waiting_parties = parties.filter(func(party: CustomerParty):
		return party != null and not party.is_queued_for_deletion() and \
			(
			party.state == CustomerParty.PartyState.WAITING_IN_LINE or \
			party.state == CustomerParty.PartyState.WALKING_TO_LINE or \
			party.state == CustomerParty.PartyState.WALKING_TO_ENTRY
			)
	)
	
	var sent_a_party_to_door = false
	for i in len(waiting_parties):
		var party = waiting_parties[i]
		if not sent_a_party_to_door:
			sent_a_party_to_door = true
			party.go_to_entry(restaurant.entry_point)
		else:
			party.wait_in_line(waiting_parties[i-1])

func _on_new_restaurant_menu_available(menu: Menu) -> void:
	if menu == null:
		return
	
	for i in len(parties):
		var party = parties[i]
		if party.state == CustomerParty.PartyState.THINKING:
			draft_order_for(party)

func draft_order_for(party: CustomerParty):
	if not restaurant.menu.is_menu_available():
		return
	
	party.order_from(restaurant.menu)

func send_customers_home(party: CustomerParty) -> void:
	party.go_home(restaurant.entry_point, restaurant.exit_point)

func clean_up_party(party: CustomerParty) -> void:
	var i = parties.find(party)
	if i == -1:
		print_debug("Couldn't find party to delete")
		return
	parties.remove_at(i)
	NetworkingUtils.send_item_for_deletion(party)
	if not is_spawning:
		is_spawning = true
		start_customer_spawning()

func _on_party_state_changed(party: CustomerParty):
	match party.state:
		CustomerParty.PartyState.WAITING_FOR_TABLE:
			check_for_available_table_for(party)
		CustomerParty.PartyState.THINKING:
			draft_order_for(party)
		CustomerParty.PartyState.LEAVING_FOR_HOME:
			send_customers_home(party)
		CustomerParty.PartyState.LEAVING_FOR_HOME_IMPATIENT:
			send_customers_home(party)
#			move_the_line()
		CustomerParty.PartyState.GONE_HOME:
			clean_up_party(party)
