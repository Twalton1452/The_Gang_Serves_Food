@icon("res://Icons/group.svg")
extends Node3D
class_name NetworkedGrouperNode3D

## Class to add/remove nodes with network safe names to a group for syncing purposes

const GROUP_NAME = "Groupers"
const CHILD_NAMING_FORMAT = "%s_%d"

## Snap the Node to this value when player's are moving it around
## Adjustable to account for non-uniformly scaled Nodes
@export var snapping_spacing = Vector3(0.05, 0.05, 0.05)
## Regardless of what you're looking at, snap to these values
@export var y_independant_snapping = false

var ID = 0
var nodes : Array[Node] : get = get_nodes

func get_nodes() -> Array[Node]:
	return get_children()

func _enter_tree():
	child_entered_tree.connect(_on_child_entered_tree)

func _ready():
	add_to_group(GROUP_NAME)

func _on_child_entered_tree(node: Node) -> void:
	generate_network_safe_name_for(node)
	snap_node.call_deferred(node)

func snap_node(node: Node) -> void:
	node.global_position = node.global_position.snapped(snapping_spacing)

func generate_network_safe_name_for(node: Node) -> void:
	node.name = CHILD_NAMING_FORMAT % [node.name, ID]
	ID += 1
