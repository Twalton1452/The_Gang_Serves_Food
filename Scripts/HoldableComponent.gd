extends Node3D
class_name HoldableComponent

## Important to set for syncing a mid-session player join
@export var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.PATTY

func _ready():
	get_parent().add_to_group(str(SCENE_ID))

#func midsession_join_sync(holder: Node3D):
#	hold(holder)
#
#func hold(holder: Node3D) -> void:
#	var item = get_parent()
#	#print("HoldableComponent is giving %s to %s" % [item.name, holder.name])
#
#	if not item.is_inside_tree():
#		holder.add_child(item, true)
#	else:
#		item.reparent(holder, false)
#	item.position = Vector3.ZERO
	
