@icon("res://Icons/wifi.svg")
extends Node
class_name NetworkedNode3D

## Heavy lifter of setting up synchronization at start up if a Player joins midsession
##
## It will automatically sync any parent node this is attached to
## Attach this Node as a child of another Node that could possibly Move or have State change
## The networked_id is used as an identifier between server/client to figure out what needs to be updated or created
## Default Properties Sync'd:
##  - position
##	- parent

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

## The lower the number the more important it is to sync
@export var priority_sync_order : SyncPriorityPhase = SyncPriorityPhase.REPARENT : set = set_priority_sync_order

## Sync with this parent node
var p_node : Node = null
var original_name : String = ""

## The SCENE_ID will point to the instantiatable Scene in SceneIds.gd
## This is pulled off the Interactable this is attached to if attached to one.
## Needs to be set in editor for non-interactables
var SCENE_ID : NetworkedIds.Scene = NetworkedIds.Scene.NETWORKED : get = get_scene_id
## Used for simple objects that need to be spawned without a stateful script
@export var override_scene_id : NetworkedIds.Scene

@export_group("Advanced")
## For singleton type nodes, set to true if you don't want the name changed
@export var only_one_will_exist = false

## Identifier between server/client to figure out what needs to be created/updated/deleted
## Generated during [method _ready]
var networked_id = -1 : set = set_networked_id

## Used by the [MidsessionJoinSyncer] script to see if it should update the Peer on spawn to reduce bandwidth
## Run-time spawns will need this set to true automatically
var changed = false


func has_after_sync():
	return "after_sync" in p_node

func has_additional_sync():
	return "set_sync_state" in p_node or "get_sync_state" in p_node

## Set the sync state of the parent including name and path information.
## Useful for syncing non-existent nodes across server/client
func set_sync_state(reader: ByteReader) -> void:
	if has_additional_sync():
		# Give the rest of the sync_state to the node to handle
		p_node.set_sync_state(reader)
	
	if has_after_sync():
		if not MidsessionJoinSyncer.is_synced:
			await MidsessionJoinSyncer.sync_complete
		p_node.after_sync()

## Get the sync state of the parent including name and path information.
## Useful for syncing non-existent nodes across server/client
func get_sync_state() -> ByteWriter:
	var writer = ByteWriter.new()
	
	# Shouldn't happen, but it could if we mistakenly try to sync before _ready gets called
	assert(networked_id != -1, "%s has -1 networked_id when trying to get_sync_state" % name)
	
	if has_additional_sync():
		# Node this is attached to properties to sync
		p_node.get_sync_state(writer)
	return writer

## Set the sync state of the parent without name and path information.
## Useful for syncing existing nodes across server/client
func set_stateful_sync_state(reader: ByteReader) -> void:
	if has_additional_sync():
		# Give the rest of the sync_state to the node to handle
		p_node.set_sync_state(reader)

## Get the sync state of the parent without name and path information
## Useful for syncing existing nodes across server/client
func get_stateful_sync_state() -> ByteWriter:
	var writer = ByteWriter.new()
	
	# Shouldn't happen, but it could if we mistakenly try to sync before _ready gets called
	assert(networked_id != -1, "%s has -1 networked_id when trying to get_sync_state" % name)
	
	if has_additional_sync():
		# Node this is attached to properties to sync
		p_node.get_sync_state(writer)
	return writer

func set_networked_id(value: int) -> void:
	networked_id = value

func get_scene_id() -> int:
	if override_scene_id != NetworkedIds.Scene.NETWORKED:
		return override_scene_id
	if has_additional_sync() and p_node.get("SCENE_ID") != null:
		return p_node.SCENE_ID
	return SCENE_ID

func set_priority_sync_order(value: SyncPriorityPhase) -> void:
	if value == priority_sync_order:
		return
	
	priority_sync_order = value
	changed = true
	# TODO revisit, sync order is being set when p_node is null
	# setting p_node during [_enter_tree] doesn't fix it
#	if p_node != null:
#		print(p_node.name, " ", priority_sync_order)

func _ready():
	# p_node on the server is set here
	# Clients have it set during MidsessionSync | Except pre-existing nodes that are in the Level scene
	if p_node == null:
		p_node = get_parent()
		original_name = p_node.name
	
	# ID is set here on the server
	# Clients will set the ID during MidsessionSync | Except pre-existing nodes that are in the Level scene
	if networked_id == -1:
		networked_id = NetworkingUtils.generate_id()
		generate_unique_name.call_deferred()
		
	add_to_group(str(NetworkedIds.Scene.NETWORKED))
	
	# This is for the server and syncing, but running it on client doesn't hurt
	if p_node is Interactable:
		SCENE_ID = p_node.SCENE_ID
		p_node.interacted.connect(_on_interaction)
	# sync overrides because they likely have no other trigger to sync them
	elif override_scene_id != NetworkedIds.Scene.NETWORKED or only_one_will_exist:
		changed = true

func _on_interaction():
	changed = true

## Keeps names unique so get_node() calls work correctly
## Note: When there are two child nodes with the same name it adds "@" symbol to the name of the most recent
## and the "@" symbol gets deleted when manually setting the name, so it messes with Paths
## As long as we keep the id which will always be unique in the name Path's should resolve
func generate_unique_name():
	if only_one_will_exist:
		return
	
	if OS.has_feature("standalone"):
		p_node.name = str(networked_id)
	else:
		p_node.name = original_name + "_" + str(networked_id) # useful for debugging

# When the node changes (parents) this gets fired off
# Can work as a delta signifier to the midsession joins for already existing nodes
func _exit_tree():
	changed = true
	
#	print("[Changed: %s] Parent: %s" % [name, get_parent().name])

func runtime_created_setup() -> void:
	p_node = get_parent()
	original_name = p_node.name
	
	# ID is set here on the server
	# Clients will set the ID during MidsessionSync | Except pre-existing nodes that are in the Level scene
	networked_id = NetworkingUtils.generate_id()
	generate_unique_name()
