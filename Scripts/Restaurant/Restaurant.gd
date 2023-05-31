extends NavigationRegion3D
class_name Restaurant

signal table_became_available(table: Table)

@export var entry_point : Node3D
@export var exit_point : Node3D
@export var tables_root : Node3D
@export var menu : Menu

var tables : Array[Table]

func _ready():
	for table in tables_root.get_children():
		if table is Table:
			table.available.connect(_on_table_available)
			tables.push_back(table)

func _on_table_available(table: Table):
	table_became_available.emit(table)

func get_next_available_table_for(party: CustomerParty) -> Table:
	for table in tables:
		if table.is_available_for(len(party.customers)):
			return table
	return null
