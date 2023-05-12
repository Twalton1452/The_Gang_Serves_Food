extends Node3D
class_name HoldableComponent

## Important to set for syncing a mid-session player join
@export var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.PATTY

var net_id = -1
var sync_state : set = set_sync_state, get = get_sync_state
# Should be set to false until it moves somewhere, but just have it set to true
# for now to update every client easily
var changed = true

func set_sync_state(value: PackedByteArray) -> int:
	position = Vector3(value.decode_half(0), value.decode_half(2), value.decode_half(4))
	var is_being_held = bool(value.decode_u8(6)) # u8 is 1 byte
	var path_size = value.decode_u8(7)
	var path_to = value.slice(8, 8 + path_size)
	var path_to_holder = path_to.get_string_from_utf8()
	var holder = get_node(path_to_holder) as HolderComponent
	if is_being_held and get_parent() != holder:
		holder.hold_item.call_deferred(self)
	elif get_parent() != holder:
		# Might need to revisit this one
		# This will only occur if we can drop Holdable's anywhere and not just into Holder's
		reparent(holder, true)
		
	# Offset to continue from, used for children of this class
	return 8 + path_size

func get_sync_state() -> PackedByteArray:
	# Shouldn't happen, but it could if we mistakenly try to sync before _ready gets called somehow
	assert(net_id != -1, "%s has -1 net_id when trying to get_sync_state" % name)
	
	# Use this flag when sync'ing state, get this path and call hold_item(this_thing)
	var is_being_held = get_parent() is HolderComponent
	var path = StringName(get_parent().get_path()).to_utf8_buffer() if is_being_held else StringName(get_path()).to_utf8_buffer()
	var buf = PackedByteArray()
	buf.resize(8)
	buf.encode_half(0, position.x) # Half is 2 bytes
	buf.encode_half(2, position.y) # Half is 2 bytes
	buf.encode_half(4, position.z) # Half is 2 bytes
	buf.encode_u8(6, is_being_held) # u8 is 1 byte
	buf.encode_u8(7, path.size()) # u8 is 1 byte - use this to decode for 8 to 8 + path.size()
	buf.append_array(path) # offset = 8 here
	return buf

func _ready():
	net_id = NetworkingUtils.generate_id()
	add_to_group(str(SCENE_ID))
	add_to_group(str(SceneIds.SCENES.HOLDABLE))

