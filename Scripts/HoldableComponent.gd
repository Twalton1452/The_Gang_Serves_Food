extends Node3D
class_name HoldableComponent

## Important to set for syncing a mid-session player join
@export var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.PATTY

var net_id = -1
var sync_state : set = set_sync_state, get = get_sync_state

func set_sync_state(value: PackedByteArray) -> void:
	pass

func get_sync_state() -> PackedByteArray:
	# Shouldn't happen, but it could if we mistakenly try to sync before _ready gets called somehow
	assert(net_id != -1, "%s has -1 net_id when trying to get_sync_state" % name)
	
	var buf = PackedByteArray()
	return buf

func _ready():
	net_id = NetworkingUtils.generate_id()
	add_to_group(str(SCENE_ID))
