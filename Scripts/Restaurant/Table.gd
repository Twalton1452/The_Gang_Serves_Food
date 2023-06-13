extends Node3D
class_name Table

signal occupied(table: Table)
signal available(table: Table)

@export var table_mesh : MeshInstance3D

@onready var patience_bar : PatienceBar = $PatienceBar


var holders : Array[Holder] = []
var chairs : Array[Chair] = []
var is_empty = true
var party_in_transit = false
var color : Color : set = set_color, get = get_color

func set_sync_state(reader: ByteReader) -> void:
	for holder in holders:
		holder.set_sync_state(reader)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	for holder in holders:
		holder.get_sync_state(writer)
	
	return writer

func _ready():
	for child in get_children():
		if child is Chair:
			chairs.push_back(child)
		elif child is Holder:
			holders.push_back(child)

func _exit_tree():
	Utils.cleanup_material_overrides(self, table_mesh)

func is_available_for(party_size: int) -> bool:
	return is_empty and not party_in_transit and table_can_hold_party(party_size)

func table_can_hold_party(party_size : int) -> bool:
	if party_size > len(chairs) or not is_empty:
		return false
		
	for chair in chairs:
		if chair.sitter != null:
			return false
	return true

func lock_for_party_in_transit():
	color = Color.DIM_GRAY
	party_in_transit = true

## Unused, but could be repurposed to be used, maybe seat_party(party)?
func seat_customers(customers: Array[Node3D]) -> bool:
	if not table_can_hold_party(len(customers)):
		return false
	
	var chair_index = 0
	for customer in customers:
		chairs[chair_index].sit(customer)
		chair_index += 1
	
	is_empty = false
	party_in_transit = false
	occupied.emit(self)
	return true

func release_customers():
	color = Color.FOREST_GREEN
	for chair in chairs:
		chair.force_sitter_out()
	is_empty = true
	party_in_transit = false
	available.emit(self)

func set_color(value: Color) -> void:
	color = value
	table_mesh.get_active_material(1).albedo_color = color

func get_color() -> Color:
	return color
