extends Node3D
class_name NetworkedNode3D

# Every NetworkedNode3D is automatically in the NETWORKED group once _ready happens
# The SCENE_ID will point to the instantiatable Scene in SceneIds.gd
@export var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.PATTY

var net_id = -1
var sync_state : set = set_sync_state, get = get_sync_state

# Used by the MidsessionSync script to see if it should update the Peer on spawn to reduce bandwidth
# Run-time spawns will need this set to true automatically
var changed = false

func set_sync_state(value: PackedByteArray) -> int:
	var sync_pos = Vector3(value.decode_half(0), value.decode_half(2), value.decode_half(4))
	var path_size = value.decode_u8(6)
	var path_to_parent = value.slice(7, 7 + path_size).get_string_from_utf8()
	var new_parent = get_node(path_to_parent)
	if get_parent() != new_parent:
		self.reparent(new_parent, false)
		position = sync_pos
	# Offset to continue from, used for children of this class
	return 7 + path_size

func get_sync_state() -> PackedByteArray:
	# Shouldn't happen, but it could if we mistakenly try to sync before _ready gets called somehow
	assert(net_id != -1, "%s has -1 net_id when trying to get_sync_state" % name)
	
	# Use this flag when sync'ing state, get this path and call hold_item(this_thing)
	var path_to_parent = StringName(get_parent().get_path()).to_utf8_buffer()
	var buf = PackedByteArray()
	buf.resize(7)
	buf.encode_half(0, position.x) # Half is 2 bytes
	buf.encode_half(2, position.y) # Half is 2 bytes
	buf.encode_half(4, position.z) # Half is 2 bytes
	buf.encode_u8(6, path_to_parent.size()) # u8 is 1 byte
	buf.append_array(path_to_parent) # offset = 7 here + path.size()
	return buf

func _ready():
	net_id = NetworkingUtils.generate_id()
	add_to_group(str(SceneIds.SCENES.NETWORKED))

# When the node changes parents this is fired off
# Can work as a delta signifier to the midsession joins
func _exit_tree():
	print("%s exited tree will need syncing" % name)
	changed = true
