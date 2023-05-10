extends Node3D
class_name HoldableComponent

## Important to set for syncing a mid-session player join
@export var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.PATTY

## Used for midsession sync's
var holding_p_id: String

func _ready():
	get_parent().add_to_group(str(SCENE_ID))

func midsession_join_sync(holder_p_id: String):
	hold(holder_p_id)

func hold(p_id: String) -> void:
	#print("HoldableComponent is giving %s to %s" % [get_parent().name, p_id])
	var player = get_node("/root/World/Players/" + p_id) as Player
	player.hold_item(get_parent())

	if not is_multiplayer_authority(): return
	holding_p_id = p_id
	
