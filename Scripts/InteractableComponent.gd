extends Area3D
class_name InteractableComponent

# Maybe rename these to: Pickup / (Combine/Interact)
signal interacted(player : Player)
signal secondary_interacted(player : Player)

var sync_state : set = set_sync_state, get = get_sync_state

func set_sync_state(value) -> int:
	return 0

func get_sync_state() -> PackedByteArray:
	return PackedByteArray()

func interact(player : Player):
	interacted.emit(player)

func secondary_interact(player : Player):
	secondary_interacted.emit(player)
