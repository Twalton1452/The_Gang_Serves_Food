extends Node3D
class_name NetworkedNode3D

## Heavy lifter of setting up synchronization at start up if a Player joins midsession
##
## It will automatically sync any Interactable above it (could likely do non-interactables too with tweaking)
## Attach this Node as a child of another Node that could possibly Move or have State change
## The networked_id is used as an identifier between server/client to figure out what needs to be updated or created
## Default Properties Sync'd:
##  - position
##	- parent


## Some Nodes are dependent on other Node's to be under the correct parent or have some state
## so this is a phased ordering structure to generate some consistency
## Set the NetworkingNode3D priority_sync_order in the editor according to how it should behave
enum SyncPriorityPhase {
	SETUP, ## Before Nodes are sync'd [br]ex: Player info, level info
	INIT_MOVED, ## Existing Nodes when a player joins moved [br]ex: All restaurants start with a Stove and it was moved from the Kitchen to outside
	CREATION, ## Create parent Nodes that will have children [br]ex: Run-time generated Plate needs to be created before food can be attached to it
	NESTED_CREATION, ## Create child Nodes that will have children [br]ex: FoodCombiner inside a run-time generated Plate
	REPARENT, ## Reparent Nodes after everything has been generated [br]ex: Existing plates are moved
	NESTED_REPARENT, ## Reparent child Nodes in complex parent/child relationships, unlikely to be used [br]ex: Existing plate reparented and existing patty became parented to that plate, need to wait for plate to reparent
	STATEFUL, ## Things that need to wait for the rest of the Nodes to finish creating/parenting [br]ex: Whether [Rotatable] is rotated or not or a [Cookable] cook progress
	DELETION, ## Delete Nodes last to make sure all the connections are setup [br]ex: Existing nodes deleted
}

## The lower the number the more important it is to sync
@export var priority_sync_order : SyncPriorityPhase = SyncPriorityPhase.REPARENT

## Sync with this parent node
@onready var p_node = get_parent()

## Every NetworkedNode3D is automatically in the NETWORKED group once [method _ready] happens
## The SCENE_ID will point to the instantiatable Scene in SceneIds.gd
## This is pulled off the Interactable this is attached to
var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.PATTY

## Identifier between server/client to figure out what needs to be created/updated/deleted
## Generated during [method _ready]
var networked_id = -1

## [PackedByteArray] of information like position, path to parent
## Appends the [member p_node] [member sync_state] to this [PackedByteArray] before sending information to the Client
var sync_state : PackedByteArray : set = set_sync_state, get = get_sync_state

## Used by the [MidsessionJoinSyncer] script to see if it should update the Peer on spawn to reduce bandwidth
## Run-time spawns will need this set to true automatically
var changed = false

func set_sync_state(value: PackedByteArray):
	var sync_pos = Vector3(value.decode_half(0), value.decode_half(2), value.decode_half(4))
	var path_size = value.decode_u8(6)
	var path_to_parent = value.slice(7, 7 + path_size).get_string_from_utf8()
	var new_parent = get_node(path_to_parent)
	if p_node.get_parent() != new_parent:
		if new_parent is Holder:
			new_parent.hold_item(p_node)
		else:
			p_node.reparent(new_parent, false)
		p_node.position = sync_pos
	
	# Give the rest of the sync_state to the node to handle
	p_node.sync_state = value.slice(7 + path_size)

func get_sync_state() -> PackedByteArray:
	# Shouldn't happen, but it could if we mistakenly try to sync before _ready gets called somehow
	assert(networked_id != -1, "%s has -1 networked_id when trying to get_sync_state" % name)
	
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
	networked_id = NetworkingUtils.generate_id()
	add_to_group(str(SceneIds.SCENES.NETWORKED))
	if p_node is Interactable:
		SCENE_ID = p_node.SCENE_ID
		p_node.interacted.connect(_on_interaction)

func _on_interaction(_player: Player):
	changed = true

# When the node changes (parents) this gets fired off
# Can work as a delta signifier to the midsession joins
func _exit_tree():
	changed = true
	#print("[Changed: %s] Parent: %s" % [name, get_parent().name])

# Could be useful
# These notifications also get fired off during less-optimal times like during game start, needs logic
# https://docs.godotengine.org/en/stable/tutorials/best_practices/godot_notifications.html
#func _notification(what):
#	match what:
#		NOTIFICATION_PARENTED:
#			changed = true
#		NOTIFICATION_UNPARENTED:
#			changed = true
#		NOTIFICATION_PREDELETE:
#			print_debug("Not Implemented Yet. Tell the Syncronizer this networked_id so midsession joins know. Deleting %s, id: " % [name, networked_id])
#			changed = true

