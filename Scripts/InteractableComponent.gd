extends Area3D
class_name InteractableComponent

signal interacted(node : InteractableComponent, player : Player)

## RPC Called from Player.gd with the "interact" action
## We pass the int id over the network and then locally they resolve it to the respective Player
@rpc("call_local", "any_peer")
func interact(player_id):
	# Kinda hacky, but it means we only need to do this in one place
	# and each client should handle the logic given the full player
	var player = get_node("/root/World/" + str(player_id))
	interacted.emit(self, player)
