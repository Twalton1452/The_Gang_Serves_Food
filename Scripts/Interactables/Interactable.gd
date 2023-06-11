@icon("res://Icons/hand_point.svg")
extends Area3D
class_name Interactable

# Maybe rename these to: Pickup / (Combine/Interact)
signal interacted
signal secondary_interacted

# This SCENE_ID will point to the instantiatable Scene in SceneIds.gd
@export var SCENE_ID : NetworkedIds.Scene

@export var mesh_to_highlight : MeshInstance3D

func set_sync_state(reader : ByteReader) -> void:
	var is_interactable = reader.read_bool()
	if is_interactable:
		enable_collider()
	else:
		disable_collider()

func get_sync_state(writer: ByteWriter) -> ByteWriter:
	writer.write_bool(is_enabled())
	return writer

func _ready():
	pass

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
	if get_node_or_null("CollisionShape3D") != null:
		$CollisionShape3D.disabled = true

func enable_collider():
	if get_node_or_null("CollisionShape3D") != null:
		$CollisionShape3D.disabled = false

func is_enabled() -> bool:
	return !$CollisionShape3D.disabled if get_node_or_null("CollisionShape3D") != null else false

func show_outline():
	pass

func hide_outline():
	pass
