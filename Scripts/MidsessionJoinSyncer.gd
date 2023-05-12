extends Node

## Syncs nodes for HolderComponents. Holders typically just reparent nodes
## Reparenting isn't out of the box supported for the MultiplayerSynchronizer
## So this helps to get things moved along and can be amended for other weirdness
func sync_nodes_for_new_player(peer_id: int):
	print("------Begin Sync for Peer %s------" % peer_id)
	
	var net_nodes = get_tree().get_nodes_in_group(str(SceneIds.SCENES.NETWORKED))
	
	for net_node in net_nodes as Array[NetworkedNode3D]:
#		if not net_node.changed:
#			continue
		
		print("[Syncing Node %s] to [Peer: %s]" % [net_node.net_id, peer_id])
		# Tell the Peer all the information it needs to get this Holdable setup
		sync_networked_node.rpc_id(peer_id, net_node.net_id, net_node.SCENE_ID, net_node.sync_state)

	NetworkingUtils.sync_id.rpc_id(peer_id, NetworkingUtils.ID)
	print("-----Finished Sync for Peer %s-----" % peer_id)

@rpc("any_peer", "reliable")
func sync_networked_node(net_id: int, net_scene_id: int, sync_state : PackedByteArray):
	var net_nodes = get_tree().get_nodes_in_group(str(SceneIds.SCENES.NETWORKED))
	#holdables[holdable_id].sync_state = sync_state
	
	print("[Peer %s] received request to [sync Node %s]" % [multiplayer.get_unique_id(), net_id])
	var synced = false

	# Find the Holdable
	for net_node in net_nodes:
		# Found the Holdable
		if net_node.net_id == net_id:
			net_node.sync_state = sync_state
			synced = true
		
	# Didn't find the Holdable, need to spawn one
	if not synced:
		assert(SceneIds.PATHS.has(net_scene_id), "%s does not have a SceneId PATH to instantiate from in SceneIds.gd")
		
		print("[Peer %s] didn't find %s in the objects on startup. The Player must have generated this at run time. [Spawning a %s with id %s]" \
			% [multiplayer.get_unique_id(), net_id, SceneIds.PATHS[net_scene_id].get_state().get_node_name(0), net_id])
		
		# Spawn Holdable
		var net_scene = SceneIds.PATHS[net_scene_id].instantiate()
		add_child(net_scene, true) # Briefly add the node into the tree so that it can call get_node from within
		net_scene.net_id = net_id
		net_scene.sync_state = sync_state

