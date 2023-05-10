extends Node

@onready var players = $"../../Players"

## Syncs nodes for HoldableComponent's. Holdable's typically just reparent nodes
## Reparenting isn't out of the box supported for the MultiplayerSynchronizer
## So this helps to get things moved along and can be amended for other weirdness
func sync_nodes_for_new_player(peer_id: int):
	print("------Begin Sync for Peer %s------" % peer_id)
	for player in players.get_children() as Array[Player]:
		# new player doesn't have anything to sync
		if player.name == str(peer_id):
			continue

		if player.is_holding_item():
			print("[Player %s] has an item. Sending info to [Peer: %s]" % [player.name, peer_id])
			var holdable = player.get_held_item().get_node("HoldableComponent") as HoldableComponent
			var holding_p_id = holdable.holding_p_id
			var holdable_scene_id = holdable.SCENE_ID
			sync_hold_node.rpc_id(peer_id, holdable.get_parent().name, holding_p_id, holdable_scene_id)
	print("-----Finished Sync for Peer %s-----" % peer_id)

@rpc("any_peer")
func sync_hold_node(node_name: String, holding_p_id: String, holdable_scene_id: int):
	print("[Peer %s] received request to [sync] for: %s. Holder: %s" % [multiplayer.get_unique_id(), node_name, holding_p_id])
	var synced = false
	for holdable_scene in get_tree().get_nodes_in_group(str(holdable_scene_id)):
		if holdable_scene.name == node_name:
			holdable_scene.get_node("HoldableComponent").midsession_join_sync(holding_p_id)
			synced = true
			break
		
	if not synced:
		print("[Peer %s] didn't find %s in the objects on startup. The Player must have generated this at run time. [Spawning a %s with name %s]" \
		% [multiplayer.get_unique_id(), node_name, SceneIds.PATHS[holdable_scene_id].get_state().get_node_name(0), node_name])
		var holdable_scene = SceneIds.PATHS[holdable_scene_id].instantiate()
		holdable_scene.name = node_name
		add_child(holdable_scene) # need to add it as a child briefly so it can reference other nodes
		holdable_scene.get_node("HoldableComponent").midsession_join_sync(holding_p_id)
