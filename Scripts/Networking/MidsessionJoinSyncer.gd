@icon("res://Icons/wifi.svg")
extends Node

var ByteReaderClass = load("res://Scripts/Networking/ByteReader.gd")
var num_nodes_syncd = 0
var total_num_nodes_to_sync = 0

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
	
	var changed_net_nodes = net_nodes.filter(func(net_node): return net_node.changed)
	begin_sync_with_peer.rpc_id(peer_id, changed_net_nodes.size())
	
	for net_node in changed_net_nodes as Array[NetworkedNode3D]:
		print_verbose("[Syncing Node %s] to [Peer: %s]" % [net_node.networked_id, peer_id])
		# Tell the Peer all the information it needs to get this NetworkedNode up to date through sync_state
		sync_networked_node.rpc_id(peer_id, net_node.networked_id, net_node.SCENE_ID, net_node.get_sync_state().data)

	NetworkingUtils.sync_id.rpc_id(peer_id, NetworkingUtils.ID)
	print_verbose("-----Finished Sync for Peer %s-----" % peer_id)
	print("[Server Result] %d/%d Nodes needed syncing for %s" % [changed_net_nodes.size(), net_nodes.size(), peer_id])
	
	unpause_for_players.rpc()

@rpc("any_peer", "reliable")
func begin_sync_with_peer(num_nodes_to_sync: int):
	print("[Peer %s] received request to begin syncing %s nodes" % [multiplayer.get_unique_id(), num_nodes_to_sync])
	total_num_nodes_to_sync = num_nodes_to_sync
	if total_num_nodes_to_sync == 0:
		finished_syncing()

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
			num_nodes_syncd += 1
		
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
		num_nodes_syncd += 1
	
	if num_nodes_syncd == total_num_nodes_to_sync:
		print("[Peer %s] finished sync with Server for %s nodes" % [multiplayer.get_unique_id(), num_nodes_syncd])
		finished_syncing()
	elif num_nodes_syncd > total_num_nodes_to_sync:
		print("[Peer %s] is syncing beyond the number of nodes intended" % [multiplayer.get_unique_id(), num_nodes_syncd])

## Client's game state is sync'd at this point
## Sync player specific settings between all clients/server
func finished_syncing():
	send_server_my_settings.rpc_id(GameState.SERVER_ID, get_settings_to_send())

## This should be some kind of PlayerSettings class that handles this and the decoding part
func get_settings_to_send() -> PackedByteArray:
	var writer = ByteWriter.new()
	var menu_mesh : MeshInstance2D = get_node("/root/World/CanvasLayer/MainMenu/MeshInstance2D")
	var color = menu_mesh.self_modulate
	writer.write_vector3(Vector3(color.r, color.g, color.b))
	return writer.data

func decode_player_settings(peer_id: int, settings: PackedByteArray) -> void:
	var player : Player = GameState.get_player_by_id(peer_id)
	
	var reader = ByteReader.new(settings)
	var color_vec3 = reader.read_vector3()
	var color = Color(color_vec3.x, color_vec3.y, color_vec3.z, 1.0)
	print_verbose("[Player %s] Received Peer %s settings" % [multiplayer.get_unique_id(), peer_id])
	
	player.set_color(color)

@rpc("any_peer")
func send_server_my_settings(settings: PackedByteArray):
	# Perform some validation of the settings, before packing it back up and sending it off
	notify_peers_of_player_settings.rpc(multiplayer.get_remote_sender_id(), settings)

@rpc("any_peer")
func send_peer_my_settings(settings: PackedByteArray):
	decode_player_settings(multiplayer.get_remote_sender_id(), settings)

@rpc("authority", "call_local")
func notify_peers_of_player_settings(peer_id: int, settings: PackedByteArray):
	decode_player_settings(peer_id, settings)
	
	if peer_id != multiplayer.get_unique_id(): # Don't send to yourself
		send_peer_my_settings.rpc_id(peer_id, get_settings_to_send())