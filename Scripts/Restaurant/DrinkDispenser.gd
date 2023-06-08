extends Node3D
class_name DrinkDispenser

signal holding_drink
signal released_drink

@export var beverage : Beverage

@onready var holder : Holder = $Holder
@onready var display : MeshInstance3D = $Dispenser/Display

var activated = false

func _ready():
	# During Syncing:
	# As long as these are connected before MidsessionJoinSyncer fires off
	# We won't need to sync the "activated" state
	holder.holding_item.connect(_on_item_entered_dispenser_zone)
	holder.released_item.connect(_on_item_left_dispenser_zone)
	display.get_active_material(0).albedo_color = beverage.color
	
func _on_item_entered_dispenser_zone(item: Node3D) -> void:
	if not item is Drink:
		return
	
	activated = true
	holding_drink.emit(self)

func _on_item_left_dispenser_zone(item: Node3D) -> void:
	activated = false
	if not item is Drink:
		return
	
	released_drink.emit(self)
