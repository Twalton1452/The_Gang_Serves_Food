extends Node3D
class_name Table

signal occupied(table: Table)
signal available(table: Table)

@export var table_mesh : MeshInstance3D
@export var color_material_index = 1

@onready var patience_bar : PatienceBar = $PatienceBar

var SCENE_ID = NetworkedIds.Scene.TABLE_FOUR

var holders : Array[Holder] = []
var chairs : Array[Chair] = []
var is_empty = true
var party_in_transit = false
var color : Color : set = set_color, get = get_color
var viable = true : get = get_viable

func set_sync_state(reader: ByteReader) -> void:
	for chair in chairs:
		chair.set_sync_state(reader)
	for holder in holders:
		holder.set_sync_state(reader)

func get_sync_state(writer: ByteWriter) -> void:
	for chair in chairs:
		chair.get_sync_state(writer)
	for holder in holders:
		holder.get_sync_state(writer)

func get_viable() -> bool:
	return available_chairs().size() > 0

func available_chairs() -> Array[Chair]:
	return chairs.filter(func(chair): return chair.sittable)

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
	var viable_chairs = available_chairs()
	if party_size > len(viable_chairs) or not is_empty:
		return false
		
	for chair in viable_chairs:
		if chair.sitter != null:
			return false
	return true

func lock_for_party_in_transit():
	color = Color.DIM_GRAY
	party_in_transit = true

func release_customers():
	color = Color.FOREST_GREEN
	for chair in available_chairs():
		chair.force_sitter_out()
	is_empty = true
	party_in_transit = false
	available.emit(self)

func set_color(value: Color) -> void:
	color = value
	table_mesh.get_active_material(color_material_index).albedo_color = color

func get_color() -> Color:
	return color
