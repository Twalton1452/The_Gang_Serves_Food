extends HoldableComponent
class_name CookableComponent

enum CookStates {
	RAW,
	COOKED,
	BURNED
}

@export var gradient : Gradient
@export var obj_to_color : MeshInstance3D

# Standard Cook Rate influenced by the Power of the Cooker
# Cook Progress increased everytime the Cooker's Timer timeout signal happens
@export var cook_rate = 0.01

@export var raw_cook_rate = 0.05
@export var cooked_cook_rate = 0.04
@export var burning_cook_rate = 0.05

# Only exposed for the Synchronizer
@export var cook_progress : float = 0.0

var material_to_color : BaseMaterial3D
var cooked_percent = 0.4
var burning_percent = 0.8
var cook_state : CookStates = CookStates.RAW

func set_sync_state(value) -> int:
	var continuing_offset = super(value)
	cook_progress = value.decode_half(continuing_offset)
	evaluate_cook_rate()
	
	return continuing_offset + 2

func get_sync_state() -> PackedByteArray:
	var buf = super()
	var end_of_parent_buf = buf.size()
	buf.resize(end_of_parent_buf + 2)
	buf.encode_half(end_of_parent_buf, cook_progress) # half is 2 bytes
	return buf

func _ready():
	#super()
	material_to_color = obj_to_color.get_active_material(0)#.get_surface_override_material(0)
	evaluate_cook_rate()
	add_to_group(str(SceneIds.SCENES.COOKABLE))

func cook(power: float):
	if cook_state == CookStates.BURNED:
		return
	
	evaluate_cook_rate()
	cook_progress += cook_rate * power

func evaluate_cook_rate():
	if cook_progress < cooked_percent:
		cook_rate = raw_cook_rate
		cook_state = CookStates.RAW
	elif cook_progress < burning_percent:
		cook_rate = cooked_cook_rate
		cook_state = CookStates.COOKED
	elif cook_progress < 1.0:
		cook_rate = burning_cook_rate
	else:
		cook_state = CookStates.BURNED
	material_to_color.albedo_color = gradient.sample(cook_progress)
