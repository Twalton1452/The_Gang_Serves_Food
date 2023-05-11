extends Node3D
class_name CookableComponent

enum CookStates {
	RAW,
	COOKED,
	BURNED
}

# Used to retrieve data about how to COOK this
@export var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.PATTY

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

func _ready():
	material_to_color = obj_to_color.get_surface_override_material(0)
	
	add_to_group(str(SceneIds.SCENES.COOKABLE))

func joined_midsession_sync(cook_prog: float):
	cook_progress = cook_prog
	evaluate_cook_rate()

func cook(power: float):
	evaluate_cook_rate()
	
	if cook_state == CookStates.BURNED:
		return
	
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
