extends NavigationRegion3D
class_name Restaurant

signal new_orderable_available(orderable: Node)
signal table_became_available(table: Table)

@export var entry_point : Node3D
@export var exit_point : Node3D
@export var tables_root : Node3D
@export var menu : Menu

var tables : Array[Table]
var path_testing_customer : Customer = null
var operable = true : get = get_operable
var baking = false

## The Restaurant is Operable if there is a single table customers can path to
func get_operable() -> bool:
	return tables.any(func(table: Table): return table.viable) and not baking

func _enter_tree() -> void:
	tables_root.child_entered_tree.connect(_on_table_entered_tables_tree)
	tables_root.child_exiting_tree.connect(_on_table_exiting_tables_tree)

func _exit_tree() -> void:
	GameState.unregister_validator(GameState.Phase.OPEN_FOR_BUSINESS, get_operable)

func _ready():
	GameState.register_validator(GameState.Phase.OPEN_FOR_BUSINESS, get_operable, "The Restaurant is not Operable!")
	path_testing_customer = load("res://Scenes/customer.tscn").instantiate()
	path_testing_customer.hide()
	add_child(path_testing_customer)
	InteractionManager.edit_mode_node_bought.connect(_on_edit_mode_node_bought)
	InteractionManager.edit_mode_node_placed.connect(_on_edit_mode_node_placed)
	GameState.state_changed.connect(_on_game_state_changed)
	new_orderable_available.connect(menu._on_new_orderable)
	
	# probablty not going to start with a drink fountain
	# this should hopefully simulate what will happen when we begin placing objects
	var drink_fountain = get_node_or_null("Building/DrinkFountain")
	if drink_fountain != null:
		new_orderable_available.emit(drink_fountain)

func _on_table_entered_tables_tree(table: Node) -> void:
	if not table is Table:
		print_debug("A non table entered the Table tree ", table)
		return
	table.available.connect(_on_table_available)
	tables.push_back(table)

func _on_table_exiting_tables_tree(table: Node) -> void:
	if not table is Table:
		print_debug("A non table exited the Table tree ", table)
		return
	
	var index = tables.find(table)
	if index == -1:
		return
	tables.remove_at(index)

func _on_edit_mode_node_bought(node: Node) -> void:
	_on_edit_mode_node_placed(node)

func _on_edit_mode_node_placed(_node: Node) -> void:
	baking = true
	await get_tree().physics_frame
	bake_navigation_mesh(false)
#	await bake_finished
	baking = false
	
	var i = 0
	while i < tables.size():
		assess_table_viability(tables[i])
		i += 1

func _on_game_state_changed() -> void:
	if GameState.state == GameState.Phase.OPEN_FOR_BUSINESS:
		#bake_navigation_mesh(true)
		pass

func _on_table_available(table: Table):
	table_became_available.emit(table)

func get_next_available_table_for(party: CustomerParty) -> Table:
	for table in tables:
		if table.is_available_for(len(party.customers)):
			return table
	return null

func assess_table_viability(table: Table) -> bool:
	for chair in table.chairs:
		chair.sittable = customer_can_path_to(chair.transition_location.global_position)
		await get_tree().physics_frame
	return table.viable

func customer_can_path_to(global_pos: Vector3) -> bool:
#	var layers = 1 | 1 << 4
#	var path = NavigationServer3D.map_get_path(NavigationServer3D.region_get_map(get_region_rid()), entry_point.global_position, global_pos, false, layers)
	path_testing_customer.global_position = entry_point.global_position
	path_testing_customer.nav_agent.target_position = global_pos
	return path_testing_customer.nav_agent.is_target_reachable()
