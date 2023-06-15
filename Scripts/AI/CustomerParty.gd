extends Node3D
class_name CustomerParty

## A group of customers makes up a CustomerParty
## This class will help to organize groups of Customers to tell them where to go like a family

signal state_changed(party: CustomerParty)
signal patience_changed(new_value: float)

## The overall state of the Party, where they are at in the Lifecycle of the process
## does not represent individual customer emotions
enum PartyState {
	SPAWNING = 0,
	
	WALKING_TO_LINE = 1,
	WAITING_IN_LINE = 2, ## PATIENCE - Walking forward only when the party ahead walks forward
	
	WALKING_TO_ENTRY = 3, ## First in line walking to the door
	WAITING_FOR_TABLE = 4, # #PATIENCE - At the front door waiting to be told a table is ready
	WALKING_TO_TABLE = 5,
	
	THINKING = 6, ## Wait Phase before transitioning to ordering for more realism
	ORDERING = 7, ## PATIENCE - Waiting for player to take their order
	
	WAITING_FOR_FOOD = 8, ## PATIENCE - Waiting for player to deliver food
	EATING = 9, ## Wait Phase before transitioning to paying for more realism
	
	WAITING_TO_PAY = 10, ## PATIENCE - Waiting for player to help them pay
	PAYING = 11, ## Wait Phase before transitioning to leaving for more realism
	LEAVING_FOR_HOME = 12, ## Traveling to the kill zone
	LEAVING_FOR_HOME_IMPATIENT = 13, ## Party got impatient
	GONE_HOME = 14, ## Traveling to the kill zone
}

## See NetworkedPartyManager for tick rate in seconds
var patience_states = {
	PartyState.WAITING_IN_LINE: {
		"rate": 0.01,
		"icon": preload("res://Sprites/CustomerPartyIcons/wait-in-line-line.png"),
		"requires_interaction": false,
	},
	PartyState.WAITING_FOR_TABLE: {
		"rate": 0.01,
		"icon": preload("res://Sprites/CustomerPartyIcons/wait-in-line-line.png"),
		"requires_interaction": false,
	},
	PartyState.THINKING: {
		"rate": 0.10,
		"icon": preload("res://Sprites/CustomerPartyIcons/brain.png"),
		"requires_interaction": false,
	},
	PartyState.ORDERING: {
		"rate": 0.02,
		"icon": preload("res://Sprites/CustomerPartyIcons/cooking-lid.png"),
		"requires_interaction": true,
	},
	PartyState.WAITING_FOR_FOOD: {
		"rate": 0.02,
		"icon": preload("res://Sprites/CustomerPartyIcons/food-plate.png"),
		"requires_interaction": false,
	},
	PartyState.WAITING_TO_PAY: {
		"rate": 0.02,
		"icon": preload("res://Sprites/CustomerPartyIcons/money-time.png"),
		"requires_interaction": true,
	},
}

var patience_expressions = [
	PixelFace.Face.Satisfied,
	PixelFace.Face.Smile,
	PixelFace.Face.Neutral,
	PixelFace.Face.Frustrated,
	PixelFace.Face.Mad,
]

var think_time_sec = 2.0
var eating_time_sec = 2.0
var paying_time_sec = 2.0
var wait_before_leave_time_sec = 1.0
var wait_between_customers_leaving = 0.2
var customer_spacing = 0.5
var customers : Array[Customer] = [] : set = set_customers
var SCENE_ID : NetworkedIds.Scene = NetworkedIds.Scene.CUSTOMER_PARTY
var patience_bar_visual : PatienceBar = null

# Saved/Loaded State
var state : PartyState = PartyState.SPAWNING : set = set_state
var num_arrived_to_destination = 0
var num_customers_required_to_advance = 1
var target_pos : Vector3 = Vector3.ZERO
var table : Table = null
var patience : float = 1.0 : set = set_patience

func after_sync():
	NetworkingUtils.sort_array_by_net_id(customers)

func set_sync_state(reader: ByteReader) -> void:
	state = reader.read_int() as PartyState
	num_arrived_to_destination = reader.read_int()
	num_customers_required_to_advance = reader.read_int()
	target_pos = reader.read_vector3()
	
	var has_table = reader.read_bool()
	if has_table:
		table = get_node(reader.read_path_to()) as Table
		table.is_empty = reader.read_bool()
		table.party_in_transit = reader.read_bool()
		table.color = reader.read_color()
	
	var has_patience_bar_visual = reader.read_bool()
	if has_patience_bar_visual:
		connect_to_patience_bar_visual(get_node(reader.read_path_to()) as PatienceBar)
	
	patience = reader.read_small_float()
	(get_parent() as CustomerManager).sync_party(self)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_int(state)
	writer.write_int(num_arrived_to_destination)
	writer.write_int(num_customers_required_to_advance)
	writer.write_vector3(target_pos)
	var has_table = table != null
	writer.write_bool(has_table)
	if has_table:
		writer.write_path_to(table)
		writer.write_bool(table.is_empty)
		writer.write_bool(table.party_in_transit)
		writer.write_color(table.color)
	
	var has_patience_bar_visual = patience_bar_visual != null
	writer.write_bool(has_patience_bar_visual)
	if has_patience_bar_visual:
		writer.write_path_to(patience_bar_visual)
	
	writer.write_small_float(patience)
	return writer

func sync_customer(customer: Customer) -> void:
	if customer in customers:
		return
	customer.arrived.connect(_on_customer_arrived)
	customer.player_interacted_with.connect(_on_customer_arrived)
	customer.got_order.connect(_on_customer_arrived)
	customer.ate_food.connect(_on_customer_arrived)
	
	customers.push_back(customer)

func set_state(value: PartyState) -> void:
	state = value
	num_arrived_to_destination = 0
	num_customers_required_to_advance = len(customers)
	emit_state_changed.call_deferred()
	
	reset_patience()
	
	if patience_states.has(state) and patience_states[state].get("requires_interaction", false):
		if table:
			table.color = Color.GOLD
	else:
		if table:
			table.color = Color.FOREST_GREEN
	#print("Party has advanced to state: %s" % str(state))

func set_patience(value: float) -> void:
	patience = value
	patience_changed.emit(patience)

func _ready():
	add_to_group(str(NetworkedIds.Scene.CUSTOMER_PARTY))

## wrapper around the signal to emit at the end of the frame
## allows the party to set all of its state before notifying others
func emit_state_changed():
	state_changed.emit(self)

func set_customers(value: Array[Customer]) -> void:
	if not customers.is_empty():
		print("Tried to set_customers for party %s when it already has customers" % name)
		return
	
	customers = value
	var spacing = 0
	for customer in customers:
		customer.arrived.connect(_on_customer_arrived)
		customer.player_interacted_with.connect(_on_customer_arrived)
		customer.got_order.connect(_on_customer_arrived)
		customer.ate_food.connect(_on_customer_arrived)
		
		customer.position = Vector3(0,0,-spacing)
		spacing += customer_spacing
	NetworkingUtils.sort_array_by_net_id(customers)
	num_customers_required_to_advance = len(customers)

func is_in_patience_state() -> bool:
	return patience_states.has(state)

func reset_patience():
	patience = 1.0
	if patience_bar_visual:
		if is_in_patience_state():
			patience_bar_visual.icon.texture = patience_states[state].icon
			patience_bar_visual.show_visual()
		else:
			patience_bar_visual.hide_visual()
		
	for customer in customers:
		customer.pixel_face.change_expression_to(patience_expressions[0])

func connect_to_patience_bar_visual(patience_bar: PatienceBar) -> void:
	if patience_bar == null:
		return
	if patience_bar_visual != null:
		disconnect_from_patience_bar_visual()
	patience_bar_visual = patience_bar
	patience_changed.connect(patience_bar_visual._on_patience_changed)
	reset_patience()

func disconnect_from_patience_bar_visual():
	if patience_bar_visual == null or not patience_changed.is_connected(patience_bar_visual._on_patience_changed):
		return
	
	patience_bar_visual.reset()
	patience_changed.disconnect(patience_bar_visual._on_patience_changed)
	patience_bar_visual.hide_visual()
	patience_bar_visual = null

func decrease_patience():
	if not is_in_patience_state():
		return
	
	patience -= patience_states[state].rate
	if patience < 0 - patience_states[state].rate: # Go a little negative as "forgiveness"
		patience_depleted()
		return
	
	var progressively_upset_expression : int = clamp(roundf(patience_expressions.size() * (1.0 - patience)), 0, patience_expressions.size() - 1)
	for customer in customers:
		customer.pixel_face.change_expression_to(patience_expressions[progressively_upset_expression])

func send_customers_to(pos: Vector3) -> void:
	target_pos = pos
	
	var spacing = 0.0
	for customer in customers:
		customer.go_to(target_pos + Vector3(0,0,-spacing))
		spacing += customer_spacing

func wait_in_line(ahead_party: CustomerParty) -> void:
	state = PartyState.WALKING_TO_LINE
	# This is for single-file line, Z-axis spacing
	# Calculate the spacing for how many customers are in the ahead party
	# Then add a distance behind them
	# var spacing_behind_party = (len(ahead_party.customers) * customer_spacing) + customer_spacing

	send_customers_to(ahead_party.target_pos + Vector3(customer_spacing,0,0))

func go_to_entry(entry: Node3D):
	send_customers_to(entry.global_position)
	
	state = PartyState.WALKING_TO_ENTRY

func wait_for_table():
	# TODO: patience bar on entry door
	pass

func go_to_table(destination_table: Table):
	table = destination_table
	table.lock_for_party_in_transit()
	target_pos = table.global_position
	
	var available_chairs = table.chairs.duplicate()
	
	for i in len(customers):
		var customer : Customer = customers[i]
		var chair_index : int = get_farthest_chair_for(customer, available_chairs)
		var chair : Chair = available_chairs[chair_index]
		customer.target_chair = chair
		available_chairs.remove_at(chair_index)
		customer.go_to(chair.transition_location.global_position)
	
	state = PartyState.WALKING_TO_TABLE

## Seat customers at tables given their farthest chair to reduce potential collisions between them
func get_farthest_chair_for(customer: Customer, chairs: Array[Chair]) -> int:
	var dist = 0.0
	var greatest_dist_index = -1
	
	for i in len(chairs):
		var chair : Chair = chairs[i]
		var customer_chair_dist = chair.global_position.distance_to(customer.global_position)
		if customer_chair_dist > dist:
			dist = customer_chair_dist
			greatest_dist_index = i
	
	return greatest_dist_index

func sit_at_table():
	for customer in customers:
		customer.sit()
	
	connect_to_patience_bar_visual(table.patience_bar)
	
	state = PartyState.THINKING

func order_from(menu: Menu) -> void:
	await get_tree().create_timer(think_time_sec).timeout
	
	# Player changed the menu from empty to a new dish while the
	# Thinking patience was running out
	if state != PartyState.THINKING:
		return
	
	NetworkedPartyManager.order_from(self, menu)

func wait_for_food():
	state = CustomerParty.PartyState.WAITING_FOR_FOOD
	for customer in customers:
		customer.interactable.disable_collider()
		customer.show_order_visual()
		customer.evaluate_food()

func eat_food() -> void:
	state = PartyState.EATING
	await get_tree().create_timer(eating_time_sec).timeout
		
	for customer in customers:
		customer.eat()

func wait_to_pay() -> void:
	for customer in customers:
		customer.interactable.enable_collider()
	
	state = CustomerParty.PartyState.WAITING_TO_PAY
	num_customers_required_to_advance = 1

func pay() -> void:
	state = PartyState.PAYING
	await get_tree().create_timer(paying_time_sec).timeout
	
	NetworkedPartyManager.pay(self)

func go_home(entry_point: Node3D, exit_point: Node3D) -> void:
	if table != null:
		table.release_customers()
		disconnect_from_patience_bar_visual()
		table = null
	target_pos = exit_point.global_position
	for customer in customers:
		customer.hide_order_visual()
		customer.target_chair = null
	await get_tree().create_timer(wait_before_leave_time_sec).timeout
	
	var customers_ordered_by_closest_to_door : Array[Customer] = customers.duplicate()
	customers_ordered_by_closest_to_door.sort_custom(func(a: Customer, b: Customer):
		if b.global_position.distance_to(entry_point.global_position) < a.global_position.distance_to(entry_point.global_position):
			return true
		return false
	)
		
	for customer in customers_ordered_by_closest_to_door:
		await get_tree().create_timer(wait_between_customers_leaving).timeout
		customer.go_to(exit_point.global_position)
	
	num_customers_required_to_advance = 1

func patience_depleted():
	state = PartyState.LEAVING_FOR_HOME_IMPATIENT
	disconnect_from_patience_bar_visual()
	for customer in customers:
		customer.pixel_face.change_expression_to(PixelFace.Face.Crying)

func _on_customer_arrived():
	num_arrived_to_destination += 1
	if not is_multiplayer_authority():
		return
	
	if num_arrived_to_destination >= num_customers_required_to_advance:
		NetworkedPartyManager.advance_party_state(self)

func advance_party_state():
	match state:
		PartyState.WALKING_TO_LINE:
			state = PartyState.WAITING_IN_LINE
		PartyState.WALKING_TO_ENTRY:
			state = PartyState.WAITING_FOR_TABLE
		PartyState.WAITING_FOR_TABLE: pass # handled by CustomerManager
		PartyState.WALKING_TO_TABLE:
			sit_at_table()
		PartyState.THINKING: pass # handled by CustomerManager
		PartyState.ORDERING:
			wait_for_food()
		PartyState.WAITING_FOR_FOOD:
			eat_food()
		PartyState.EATING:
			wait_to_pay()
		PartyState.WAITING_TO_PAY:
			pay()
		PartyState.PAYING: pass # just a wait phase for now
		PartyState.LEAVING_FOR_HOME,PartyState.LEAVING_FOR_HOME_IMPATIENT:
			state = PartyState.GONE_HOME
		PartyState.GONE_HOME: pass # handled by CustomerManager
