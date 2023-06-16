extends Node3D
class_name DrinkDispenser

signal holding_drink
signal released_drink

@export var beverage : Beverage

@onready var holder : Holder = $Holder
@onready var display : MeshInstance3D = $Dispenser/Display

@onready var fluid : Node3D = $Fluid
@onready var fluid_pivot : Node3D = $Fluid/Pivot
@onready var fluid_mesh : MeshInstance3D = $Fluid/Pivot/Fluid


var fluid_tween : Tween = null
var activated = false : set = set_activated

func set_activated(value: bool) -> void:
	activated = value
	
	if activated:
		if fluid_tween != null and fluid_tween.is_valid():
			fluid_tween.kill()
		fluid_pivot.scale = Vector3(0.0, 0.1, 0.0)
		fluid.show()
		fluid_tween = create_tween()
		fluid_tween.tween_property(fluid_pivot, "scale", Vector3(1.0, 1.75, 1.0), 0.3).set_ease(Tween.EASE_IN)
		
	else:
		if fluid_tween != null and fluid_tween.is_valid():
			fluid_tween.kill()
		fluid_tween = create_tween()
		fluid_tween.tween_property(fluid_pivot, "scale", Vector3(0.0, 1.75, 0.0), 0.2).set_ease(Tween.EASE_OUT)
		fluid_tween.tween_callback(func(): fluid.hide())

func _ready():
	# During Syncing:
	# As long as these are connected before MidsessionJoinSyncer fires off
	# We won't need to sync the "activated" state
	holder.holding_item.connect(_on_item_entered_dispenser_zone)
	holder.released_item.connect(_on_item_left_dispenser_zone)
	display.get_active_material(0).albedo_color = beverage.color
	fluid_mesh.set_instance_shader_parameter("color", beverage.color)
	
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
