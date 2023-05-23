extends Area3D
class_name Interactable

# Maybe rename these to: Pickup / (Combine/Interact)
signal interacted(player : Player)
signal secondary_interacted(player : Player)

# This SCENE_ID will point to the instantiatable Scene in SceneIds.gd
# Will also be used for interactable on interactable interactions like combining food
@export var SCENE_ID : SceneIds.SCENES = SceneIds.SCENES.NETWORKED

@export var mesh_to_highlight : MeshInstance3D
#@export var highlight_mesh : MeshInstance3D

var sync_state : set = set_sync_state, get = get_sync_state

func set_sync_state(_value : PackedByteArray) -> int:
	return 0

func get_sync_state() -> PackedByteArray:
	return PackedByteArray()

func _ready():
	pass

func _interact(_player : Player):
	pass

# Calls an internal _interact method so we dont have to keep calling "super()"
# to make sure the "interacted" signal is emitted
func interact(player : Player):
	interacted.emit(player)
	return _interact(player)

func _secondary_interact(_player : Player):
	pass

# Calls an internal _secondary_interact method so we dont have to keep calling "super()"
# to make sure the "secondary_interacted" signal is emitted
func secondary_interact(player : Player):
	secondary_interacted.emit(player)
	return _secondary_interact(player)

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
#	if highlight_mesh:
#		highlight_mesh.show()

func hide_outline():
	pass
#	if highlight_mesh:
#		highlight_mesh.hide()
