extends Node3D
class_name HoldableComponent

## Important to set for syncing a mid-session player join
@export var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.PATTY

func _ready():
	get_parent().add_to_group(str(SCENE_ID))
