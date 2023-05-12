extends Node

## Syncs nodes for HolderComponents. Holders typically just reparent nodes
## Reparenting isn't out of the box supported for the MultiplayerSynchronizer
## So this helps to get things moved along and can be amended for other weirdness
func sync_nodes_for_new_player(peer_id: int):
	print("------Begin Sync for Peer %s------" % peer_id)
	
	var holdables = get_tree().get_nodes_in_group(str(SceneIds.SCENES.HOLDABLE))
	
	for holdable in holdables as Array[HoldableComponent]:
		if not holdable.changed:
			continue
		
		print("[Holdable %s] has changed. Syncing info to [Peer: %s]" % [holdable.net_id, peer_id])
		# Tell the Peer all the information it needs to get this Holdable setup
		sync_holdable_node.rpc_id(peer_id, holdable.net_id, holdable.SCENE_ID, holdable.sync_state)

	NetworkingUtils.sync_id.rpc_id(peer_id, NetworkingUtils.ID)
	print("-----Finished Sync for Peer %s-----" % peer_id)

@rpc("any_peer", "reliable")
func sync_holdable_node(holdable_id: int, holdable_scene_id: int, sync_state : PackedByteArray):
	var holdables = get_tree().get_nodes_in_group(str(SceneIds.SCENES.HOLDABLE))
	#holdables[holdable_id].sync_state = sync_state
	
	print("[Peer %s] received request to [sync Holdable %s]" % [multiplayer.get_unique_id(), holdable_id])
	var synced = false

	# Find the Holdable
	for holdable_scene in holdables:
		# Found the Holdable
		if holdable_scene.net_id == holdable_id:
			(holdable_scene as HoldableComponent).sync_state = sync_state
			synced = true
		
	# Didn't find the Holdable, need to spawn one
	if not synced:
		print("[Peer %s] didn't find %s in the objects on startup. The Player must have generated this at run time. [Spawning a %s with id %s]" \
			% [multiplayer.get_unique_id(), holdable_id, SceneIds.PATHS[holdable_scene_id].get_state().get_node_name(0), holdable_id])
		
		# Spawn Holdable
		var holdable_scene = SceneIds.PATHS[holdable_scene_id].instantiate()
		add_child(holdable_scene, true) # Briefly add the node into the tree so that it can call get_node from within
		holdable_scene.net_id = holdable_id
		holdable_scene.sync_state = sync_state

