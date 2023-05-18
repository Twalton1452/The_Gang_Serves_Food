extends Node3D
class_name NetworkedNode3D

# Every NetworkedNode3D is automatically in the NETWORKED group once _ready happens
# The SCENE_ID will point to the instantiatable Scene in SceneIds.gd
@export var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.PATTY
# The lower the number the more important it is to sync
@export var priority_sync_order = 0

# Sync with this node
@onready var p_node = get_parent()

var net_id = -1
var sync_state : set = set_sync_state, get = get_sync_state

# Used by the MidsessionSync script to see if it should update the Peer on spawn to reduce bandwidth
# Run-time spawns will need this set to true automatically
var changed = false

func set_sync_state(value: PackedByteArray):
	var sync_pos = Vector3(value.decode_half(0), value.decode_half(2), value.decode_half(4))
	var path_size = value.decode_u8(6)
	var path_to_parent = value.slice(7, 7 + path_size).get_string_from_utf8()
	var new_parent = get_node(path_to_parent)
	if p_node.get_parent() != new_parent:
		p_node.reparent(new_parent, false)
		p_node.position = sync_pos
	# Give the rest of the sync_state to the node to handle
	p_node.sync_state = value.slice(7 + path_size)

func get_sync_state() -> PackedByteArray:
	# Shouldn't happen, but it could if we mistakenly try to sync before _ready gets called somehow
	assert(net_id != -1, "%s has -1 net_id when trying to get_sync_state" % name)
	
	# Default properties to Sync
	var path_to_parent = StringName(p_node.get_parent().get_path()).to_utf8_buffer()
	var buf = PackedByteArray()
	buf.resize(7)
	buf.encode_half(0, p_node.position.x) # Half is 2 bytes
	buf.encode_half(2, p_node.position.y) # Half is 2 bytes
	buf.encode_half(4, p_node.position.z) # Half is 2 bytes
	buf.encode_u8(6, path_to_parent.size()) # u8 is 1 byte
	buf.append_array(path_to_parent) # offset = 7 here + path.size()
	
	# Node this is attached to properties to sync
	buf.append_array(p_node.sync_state)
	return buf

func _ready():
	net_id = NetworkingUtils.generate_id()
	add_to_group(str(SceneIds.SCENES.NETWORKED))
	if p_node is InteractableComponent:
		p_node.interacted.connect(_on_interaction)

func _on_interaction(_player: Player):
	changed = true

# When the node changes (parents) this gets fired off
# Can work as a delta signifier to the midsession joins
func _exit_tree():
	changed = true
	#print("[Changed: %s] Parent: %s" % [name, get_parent().name])

# Could be useful
# These notifications also get fired off during less-optimal times, needs logic
# https://docs.godotengine.org/en/stable/tutorials/best_practices/godot_notifications.html
#func _notification(what):
#	match what:
#		NOTIFICATION_PARENTED:
#			changed = true
#		NOTIFICATION_UNPARENTED:
#			changed = true
#		NOTIFICATION_PREDELETE:
#			print_debug("Not Implemented Yet. Tell the Syncronizer this net_id so midsession joins know. Deleting %s, id: " % [name, net_id])
#			changed = true

