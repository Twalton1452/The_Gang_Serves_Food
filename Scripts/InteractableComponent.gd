extends Area3D
class_name InteractableComponent

# Maybe rename these to: Pickup / (Combine/Interact)
signal interacted(player : Player)
signal secondary_interacted(player : Player)

var sync_state : set = set_sync_state, get = get_sync_state

func set_sync_state(_value : PackedByteArray) -> int:
	return 0

func get_sync_state() -> PackedByteArray:
	return PackedByteArray()

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

