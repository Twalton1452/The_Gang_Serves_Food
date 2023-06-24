@icon("res://Icons/hand_point.svg")
extends Area3D
class_name Interactable

signal interacted
signal secondary_interacted

const INTERACTABLE_LAYER = 3
const NON_INTERACTABLE_LAYER = 7

## This SCENE_ID will point to the instantiatable Scene in NetworkedScenes.gd
@export var SCENE_ID : NetworkedIds.Scene

@export var mesh_to_highlight : MeshInstance3D

var collider : CollisionShape3D

func _exit_tree():
	Utils.cleanup_material_overrides(self, mesh_to_highlight)

func set_sync_state(reader : ByteReader) -> void:
	var collider_enabled = reader.read_bool()
	if collider_enabled:
		enable_collider()
	else:
		disable_collider()
	
	var interactable_layer_enabled = reader.read_bool()
	if not interactable_layer_enabled:
		set_collision_layer_value(INTERACTABLE_LAYER, false)
		set_collision_layer_value(NON_INTERACTABLE_LAYER, true)

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_bool(is_collider_enabled())
	writer.write_bool(get_collision_layer_value(INTERACTABLE_LAYER))
	return writer

func _ready():
	collider = get_node_or_null("CollisionShape3D")

func _interact(_player : Player):
	pass

# Calls an internal _interact method so we dont have to keep calling "super()"
# to make sure the "interacted" signal is emitted
func interact(player : Player):
	var result = _interact(player)
	interacted.emit()
	return result

func _secondary_interact(_player : Player):
	pass

# Calls an internal _secondary_interact method so we dont have to keep calling "super()"
# to make sure the "secondary_interacted" signal is emitted
func secondary_interact(player : Player):
	var result = _secondary_interact(player)
	secondary_interacted.emit()
	return result

func disable_collider():
	if collider != null:
		collider.disabled = true

func enable_collider():
	if collider != null:
		collider.disabled = false

func is_collider_enabled() -> bool:
	if collider == null:
		return false
	return !collider.disabled

func show_outline():
	pass

func hide_outline():
	pass
