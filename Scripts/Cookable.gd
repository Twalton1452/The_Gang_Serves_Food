extends Holdable
class_name Cookable

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

var cook_progress : float = 0.0

var material_to_color : BaseMaterial3D
var cooked_percent = 0.4
var burning_percent = 0.8
var cook_state : CookStates = CookStates.RAW

func set_sync_state(reader: ByteReader) -> void:
	super(reader)
	cook_progress = reader.read_float()
	evaluate_cook_rate()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	super(writer)
	writer.write_float(cook_progress) # half is 2 bytes
	return writer

func _ready():
	#super()
	if obj_to_color == null:
		for child in get_children():
			if child is MeshInstance3D:
				obj_to_color = child
				print("%s didn't have a MeshInstance3D assigned so it looked in its children and found: %s" % [name, obj_to_color.name])
				break
	assert(obj_to_color != null, "%s doesn't have a MeshInstance3D assigned to obj_to_color" % name)

	material_to_color = obj_to_color.get_active_material(0)#.get_surface_override_material(0)
	evaluate_cook_rate()

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
