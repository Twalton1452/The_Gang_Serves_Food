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
	SETUP, ## Before Nodes are sync'd [br]ex: Level info
	INIT_MOVED, ## Existing Nodes when a player joins moved [br]ex: All restaurants start with a Stove and it was moved from the Kitchen to outside
	AI_SETUP, ## Spawned Parties
	AI_CREATION, ## Spawned Customers
	AI_CREATION_NESTED, ## Dynamically generated child components
	CREATION, ## Create parent Nodes that will have children [br]ex: Run-time generated Plate needs to be created before food can be attached to it
	NESTED_CREATION, ## Create child Nodes that will have children [br]ex: FoodCombiner inside a run-time generated Plate
	REPARENT, ## Reparent Nodes after everything has been generated [br]ex: Existing plates are moved
	NESTED_REPARENT, ## Reparent child Nodes in complex parent/child relationships [br]ex: Plate was reparented and Patty became parented to that plate, need to wait for plate to reparent
	STATEFUL, ## Things that need to wait for the rest of the Nodes to finish creating/parenting [br]ex: Whether [Rotatable] is rotated or not or a [Cookable] cook progress
	DELETION, ## Delete Nodes last to make sure all the connections are setup [br]ex: Existing nodes deleted
}

@export var sync_position = true
## The lower the number the more important it is to sync
@export var priority_sync_order : SyncPriorityPhase = SyncPriorityPhase.REPARENT

## Sync with this parent node
@onready var p_node = get_parent()

## Every NetworkedNode3D is automatically in the NETWORKED group once [method _ready] happens
## The SCENE_ID will point to the instantiatable Scene in SceneIds.gd
## This is pulled off the Interactable this is attached to.
## Needs to be set in editor for non-interactables
var SCENE_ID : NetworkedIds.Scene = NetworkedIds.Scene.NETWORKED : get = get_scene_id
## Used for simple objects that need to be spawned but have no script attached to them
@export var override_scene_id : NetworkedIds.Scene

## Identifier between server/client to figure out what needs to be created/updated/deleted
## Generated during [method _ready]
var networked_id = -1

## Used by the [MidsessionJoinSyncer] script to see if it should update the Peer on spawn to reduce bandwidth
## Run-time spawns will need this set to true automatically
var changed = false

func has_after_sync():
	return "after_sync" in p_node

func has_additional_sync():
	return "set_sync_state" in p_node or "get_sync_state" in p_node

func set_sync_state(reader: ByteReader):
	var global_sync_pos : Vector3
	if sync_position:
		global_sync_pos = reader.read_vector3()
	
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
		
	if sync_position:
		p_node.global_position = global_sync_pos
	
	if has_additional_sync():
		# Give the rest of the sync_state to the node to handle
		p_node.set_sync_state(reader)
	
	if has_after_sync():
		await MidsessionJoinSyncer.sync_complete
		p_node.after_sync()

func get_sync_state() -> ByteWriter:
	var writer : ByteWriter = ByteWriterClass.new()
	
	# Shouldn't happen, but it could if we mistakenly try to sync before _ready gets called
	assert(networked_id != -1, "%s has -1 networked_id when trying to get_sync_state" % name)
	
	# Default properties to Sync
	if sync_position:
		writer.write_vector3(p_node.global_position)
	writer.write_path_to(p_node)
	
	if has_additional_sync():
		# Node this is attached to properties to sync
		p_node.get_sync_state(writer)
	return writer

func get_scene_id() -> int:
	if override_scene_id != NetworkedIds.Scene.NETWORKED:
		return override_scene_id
	if has_additional_sync():
		return p_node.SCENE_ID
	return SCENE_ID

func _ready():
	networked_id = NetworkingUtils.generate_id()
	generate_unique_name()
	add_to_group(str(NetworkedIds.Scene.NETWORKED))
	if p_node is Interactable:
		SCENE_ID = p_node.SCENE_ID
		p_node.interacted.connect(_on_interaction)

func _on_interaction():
	changed = true

## Keeps names unique so get_node() calls work correctly
## Note: When there are two child nodes with the same name it adds "@" symbol to the name of the most recent
## and the "@" symbol gets deleted when manually setting the name, so it messes with Paths
## As long as we keep the id which will always be unique in the name Path's should resolve
func generate_unique_name():
	if OS.has_feature("standalone"):
		p_node.name = str(networked_id)
	else:
		p_node.name = p_node.name + "_" + str(networked_id) # useful for debugging

# When the node changes (parents) this gets fired off
# Can work as a delta signifier to the midsession joins
func _exit_tree():
	changed = true
#	print("[Changed: %s] Parent: %s" % [name, get_parent().name])
