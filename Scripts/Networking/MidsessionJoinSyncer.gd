@icon("res://Icons/wifi.svg")
extends Node

var ByteReaderClass = load("res://Scripts/Networking/ByteReader.gd")

@rpc("call_local", "reliable")
func pause_for_players():
	get_tree().paused = true

@rpc("call_local", "reliable")
func unpause_for_players():
	get_tree().paused = false

## Syncs nodes for Networked Nodes on spawn to ease midsession join synchronization
func sync_nodes_for_new_player(peer_id: int):
	pause_for_players.rpc()
	
	print_verbose("------Begin Sync for Peer %s------" % peer_id)
	var net_nodes = get_tree().get_nodes_in_group(str(SceneIds.SCENES.NETWORKED))
	
	# Sync MultiHolders first because other objects need to get parented to them
	# Lower number for priority is sync'd first
	net_nodes.sort_custom(func(a: NetworkedNode3D, b: NetworkedNode3D):
		if a.priority_sync_order < b.priority_sync_order:
			return true
		return false
	)
	
	var not_synced = 0
	for net_node in net_nodes as Array[NetworkedNode3D]:
		if not net_node.changed:
			#print("[Not Syncing Node %s] hasn't changed" % net_node.networked_id)
			not_synced += 1
			continue
		
		print_verbose("[Syncing Node %s] to [Peer: %s]" % [net_node.networked_id, peer_id])
		# Tell the Peer all the information it needs to get this NetworkedNode up to date through sync_state
		sync_networked_node.rpc_id(peer_id, net_node.networked_id, net_node.SCENE_ID, net_node.get_sync_state().data)

	NetworkingUtils.sync_id.rpc_id(peer_id, NetworkingUtils.ID)
	print_verbose("-----Finished Sync for Peer %s-----" % peer_id)
	print("[Result] %d/%d Nodes needed syncing for %s" % [net_nodes.size() - not_synced, net_nodes.size(), peer_id])
	
	unpause_for_players.rpc()

@rpc("any_peer", "reliable")
func sync_networked_node(networked_id: int, net_scene_id: int, sync_state : PackedByteArray):
	var net_nodes = get_tree().get_nodes_in_group(str(SceneIds.SCENES.NETWORKED))
	var sync_state_reader : ByteReader = ByteReaderClass.new(sync_state)
	#print("[Peer %s] received request to [sync Node %s]" % [multiplayer.get_unique_id(), networked_id])
	var synced = false

	# Find the Networked Node
	for net_node in net_nodes:
		# Found the Networked Node
		if net_node.networked_id == networked_id:
			net_node.set_sync_state(sync_state_reader)
			synced = true
		
	# Didn't find the Networked Node, need to spawn one
	if not synced:
		assert(SceneIds.PATHS[net_scene_id] != null, "%s does not have a SceneId PATH to instantiate from in SceneIds.gd")
		
		print_verbose("[Peer %s] didn't find %s in the objects on startup. The Player must have generated this at run time. [Spawning a %s with id %s]" \
			% [multiplayer.get_unique_id(), networked_id, SceneIds.PATHS[net_scene_id].get_state().get_node_name(0), networked_id])
		
		# Spawn Networked Node
		var net_scene = SceneIds.PATHS[net_scene_id].instantiate()
		add_child(net_scene) # Briefly add the node into the tree so that it can call get_node from within
		var net_node = net_scene.get_node("NetworkedNode3D")
		net_node.networked_id = networked_id
		net_node.set_sync_state(sync_state_reader)
		net_node.changed = true

