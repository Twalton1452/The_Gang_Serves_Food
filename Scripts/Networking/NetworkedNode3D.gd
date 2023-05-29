@icon("res://Icons/wifi.svg")
extends Node
class_name NetworkedNode3D

## Heavy lifter of setting up synchronization at start up if a Player joins midsession
##
## It will automatically sync any Interactable above it (could likely do non-interactables too with tweaking)
## Attach this Node as a child of another Node that could possibly Move or have State change
## The networked_id is used as an identifier between server/client to figure out what needs to be updated or created
## Default Properties Sync'd:
##  - position
##	- parent

var ByteWriterClass = load("res://Scripts/Networking/ByteWriter.gd")

## Some Nodes are dependent on other Node's to be under the correct parent or have some state
## so this is a phased ordering structure to generate some consistency
## Set the NetworkingNode3D priority_sync_order in the editor according to how it should behave
enum SyncPriorityPhase {
	SETUP, ## Before Nodes are sync'd [br]ex: Player info, level info
	INIT_MOVED, ## Existing Nodes when a player joins moved [br]ex: All restaurants start with a Stove and it was moved from the Kitchen to outside
	CREATION, ## Create parent Nodes that will have children [br]ex: Run-time generated Plate needs to be created before food can be attached to it
	NESTED_CREATION, ## Create child Nodes that will have children [br]ex: FoodCombiner inside a run-time generated Plate
	REPARENT, ## Reparent Nodes after everything has been generated [br]ex: Existing plates are moved
	NESTED_REPARENT, ## Reparent child Nodes in complex parent/child relationships [br]ex: Existing plate reparented and existing patty became parented to that plate, need to wait for plate to reparent
	STATEFUL, ## Things that need to wait for the rest of the Nodes to finish creating/parenting [br]ex: Whether [Rotatable] is rotated or not or a [Cookable] cook progress
	DELETION, ## Delete Nodes last to make sure all the connections are setup [br]ex: Existing nodes deleted
}

## The lower the number the more important it is to sync
@export var priority_sync_order : SyncPriorityPhase = SyncPriorityPhase.REPARENT

## Sync with this parent node
@onready var p_node = get_parent()

## Every NetworkedNode3D is automatically in the NETWORKED group once [method _ready] happens
## The SCENE_ID will point to the instantiatable Scene in SceneIds.gd
## This is pulled off the Interactable this is attached to.
## Needs to be set in editor for non-interactables
var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.NETWORKED : get = get_scene_id
## Used for simple objects that need to be spawned but have no script attached to them
@export var override_scene_id : SceneIds.SCENES

## Identifier between server/client to figure out what needs to be created/updated/deleted
## Generated during [method _ready]
var networked_id = -1

## Used by the [MidsessionJoinSyncer] script to see if it should update the Peer on spawn to reduce bandwidth
## Run-time spawns will need this set to true automatically
var changed = false

func has_additional_sync():
	return "set_sync_state" in p_node or "get_sync_state" in p_node

func set_sync_state(reader: ByteReader):
	var global_sync_pos = reader.read_vector3()
	var path_to = reader.read_path_to()
	
	var split_path : PackedStringArray = path_to.split("/")
	var new_name = split_path[-1]
	var path_to_parent = "/".join(split_path.slice(0, -1))
	#print("syncing %s Path to Parent %s" % [new_name, path_to_parent])
	var new_parent = get_node(path_to_parent)
	
	get_parent().name = new_name
	if p_node.get_parent() != new_parent:
		if p_node.get_parent() is Holder and new_parent is Holder:
			p_node.get_parent().release_this_item_to(p_node, new_parent)
		elif new_parent is Holder:
			new_parent.hold_item(p_node)
		else:
			p_node.reparent(new_parent, false)
	p_node.global_position = global_sync_pos
	
	if has_additional_sync():
		# Give the rest of the sync_state to the node to handle
		p_node.set_sync_state(reader)

func get_sync_state() -> ByteWriter:
	var writer : ByteWriter = ByteWriterClass.new()
	
	# Shouldn't happen, but it could if we mistakenly try to sync before _ready gets called somehow
	assert(networked_id != -1, "%s has -1 networked_id when trying to get_sync_state" % name)
	
	# Default properties to Sync
	writer.write_vector3(p_node.global_position)
	writer.write_path_to(p_node)
	
	if has_additional_sync():
		# Node this is attached to properties to sync
		p_node.get_sync_state(writer)
	return writer

func get_scene_id() -> int:
	if override_scene_id != SceneIds.SCENES.NETWORKED:
		return override_scene_id
	if has_additional_sync():
		return p_node.SCENE_ID
	return SCENE_ID

func _ready():
	networked_id = NetworkingUtils.generate_id()
	generate_unique_name()
	add_to_group(str(SceneIds.SCENES.NETWORKED))
	if p_node is Interactable:
		SCENE_ID = p_node.SCENE_ID
		p_node.interacted.connect(_on_interaction)
	if priority_sync_order == SyncPriorityPhase.CREATION or priority_sync_order == SyncPriorityPhase.NESTED_CREATION:
		changed = true

func _on_interaction(_player: Player):
	changed = true

## Sets parameters required for midsession syncing
func generated_at_run_time_setup():
	priority_sync_order = SyncPriorityPhase.CREATION
	changed = true
	#print("I generated %s at run time | Path: %s" % [p_node.name, p_node.get_path()])

## Keeps names unique so get_node() calls work correctly
## When a name collision happens between child nodes it adds "@" symbol to the name
## and the "@" symbol gets deleted when manually setting the name, so it messes with Paths
## As long as we keep the id which will always be unique in the name Path's should resolve
func generate_unique_name():
	p_node.name = p_node.name + "_" + str(networked_id)

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

