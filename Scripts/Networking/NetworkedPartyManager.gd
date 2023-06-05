extends Node

# Autoloaded

## Class to handle all of the RPC's related to party spawning and state changes

var patience_timer : Timer
var patience_tick_rate_seconds = 1.0

func _ready():
	# For Autoload's this isn't reliable
	if not is_multiplayer_authority():
		return
	
	patience_timer = Timer.new()
	add_child(patience_timer)
	patience_timer.timeout.connect(_on_patience_tick)
	
	GameState.state_changed.connect(_on_game_state_changed)
	_on_game_state_changed()

func _on_game_state_changed():
	if not is_multiplayer_authority():
		return
	
	if GameState.state == GameState.Phase.OPEN_FOR_BUSINESS:
		patience_timer.start(patience_tick_rate_seconds)
	else:
		patience_timer.stop()

func _on_patience_tick():
	if not is_multiplayer_authority():
		return
	
	notify_patience_tick.rpc()

@rpc("authority", "call_local")
func notify_patience_tick():
	get_tree().call_group(str(NetworkedIds.Scene.CUSTOMER_PARTY), "decrease_patience")

func get_parties():
	return get_tree().get_nodes_in_group(str(NetworkedIds.Scene.CUSTOMER_PARTY))

func get_party_by_name(party_name: String) -> CustomerParty:
	for party in get_parties():
		if party.name == party_name:
			return party
	return null

func advance_party_state(party: CustomerParty):
	if not is_multiplayer_authority():
		return
	
	var party_name = StringName(party.name).to_utf8_buffer()
	notify_advance_party_state.rpc(party_name)

## call_local so everyone advances the same way
@rpc("authority", "call_local")
func notify_advance_party_state(data: PackedByteArray):
	var party_name = data.get_string_from_utf8()
	var party : CustomerParty = get_party_by_name(party_name)
	if party == null:
		return
	
	party.advance_party_state()

func order_from(party: CustomerParty, menu: Menu):
	if not is_multiplayer_authority():
		return
	
	for customer in party.customers:
		customer.order_from(menu)
	
	party.state = CustomerParty.PartyState.ORDERING
	party.num_customers_required_to_advance = 1
	
	var writer = ByteWriter.new()
	writer.write_str(party.name)
	for customer in party.customers:
		writer.write_int_array(customer.order as Array[int])
	
	notify_peers_of_order.rpc(writer.data)

## call_remote as the server should decide the order for customers and tell clients
@rpc("authority", "call_remote")
func notify_peers_of_order(order_data: PackedByteArray):
	var reader = ByteReader.new(order_data)
	var party_name = reader.read_str()
	var party : CustomerParty = get_party_by_name(party_name)
	if party == null:
		return

	for customer in party.customers:
		customer.order = reader.read_int_array() as Array[NetworkedIds.Scene]
	
	party.state = CustomerParty.PartyState.ORDERING
	party.num_customers_required_to_advance = 1
	

func pay(party: CustomerParty):
	if not is_multiplayer_authority():
		return
	
	GameState.add_money(1)
	
	party.state = CustomerParty.PartyState.LEAVING_FOR_HOME
	party.num_customers_required_to_advance = 1
	
	var writer = ByteWriter.new()
	writer.write_str(party.name)
	
	notify_peers_of_pay.rpc(writer.data)

@rpc("authority", "call_remote")
func notify_peers_of_pay(data: PackedByteArray):
	var reader = ByteReader.new(data)
	var party_name = reader.read_str()
	var party : CustomerParty = get_party_by_name(party_name)
	if party == null:
		return
	
	
	party.state = CustomerParty.PartyState.LEAVING_FOR_HOME
	party.num_customers_required_to_advance = 1
