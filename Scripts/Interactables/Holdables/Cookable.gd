extends Holdable
class_name Cookable

enum CookStates {
	RAW = 0,
	COOKED = 1,
	BURNED = 2
}

@export var gradient : Gradient
@export var obj_to_color : MeshInstance3D
@export var cook_state_rates : Dictionary = {
	CookStates.RAW: 0.05,
	CookStates.COOKED: 0.04,
	CookStates.BURNED: 0.05,
}

var cook_state_progress = {
	CookStates.RAW: 0.0,
	CookStates.COOKED: 0.0,
	CookStates.BURNED: 0.0,
}

var material_to_color : BaseMaterial3D
var cooked_percent = 0.4
var burning_percent = 0.8
var cook_state : CookStates = CookStates.RAW
var cook_progress : get = get_current_cook_progress

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	cook_state_progress[CookStates.RAW] = reader.read_small_float()
	cook_state_progress[CookStates.COOKED] = reader.read_small_float()
	cook_state_progress[CookStates.BURNED] = reader.read_small_float()
	evaluate_cook_rate()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	writer.write_small_float(cook_state_progress[CookStates.RAW])
	writer.write_small_float(cook_state_progress[CookStates.COOKED])
	writer.write_small_float(cook_state_progress[CookStates.BURNED])
	return writer

func get_current_cook_progress() -> float:
	return cook_state_progress[cook_state]

func _ready():
	super()
	if obj_to_color == null:
		for child in get_children():
			if child is MeshInstance3D:
				obj_to_color = child
				print("%s didn't have a MeshInstance3D assigned so it looked in its children and found: %s" % [name, obj_to_color.name])
				break
	assert(obj_to_color != null, "%s doesn't have a MeshInstance3D assigned to obj_to_color" % name)
	assert(gradient != null, "%s doesn't have a gradient" % name)

	material_to_color = obj_to_color.get_active_material(0)
	material_to_color.albedo_color = gradient.colors[cook_state % gradient.colors.size()]
	evaluate_cook_rate()

func cook(power: float):
	if cook_state == CookStates.BURNED:
		return
	
	cook_state_progress[cook_state] += cook_state_rates[cook_state] * power
	evaluate_cook_rate()

func evaluate_cook_rate():
	if cook_state_progress[cook_state] >= 1.0:
		@warning_ignore("int_as_enum_without_cast")
		cook_state += 1 as CookStates
		material_to_color.albedo_color = gradient.colors[cook_state % gradient.colors.size()]
