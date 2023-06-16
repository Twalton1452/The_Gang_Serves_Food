@icon("res://Icons/wifi.svg")
extends Node

## Autoloaded

signal sync_complete

var syncing = {}
var num_nodes_syncd = 0
var total_num_nodes_to_sync = 0
var num_packets_to_incur_wait = 200
var seconds_to_wait_between_many_packets = 0.1

var is_synced = false : get = get_is_synced

func get_is_synced() -> bool:
	return num_nodes_syncd == total_num_nodes_to_sync

@rpc("call_local", "reliable")
func pause_for_players():
	GameState.hud.display_notification("A Player is joining...")
	get_tree().paused = true

@rpc("call_local", "reliable")
func unpause_for_players(unpaused_peer_id: int):
	GameState.hud.hide_notification()
	syncing[unpaused_peer_id] = false
	get_tree().paused = false

## Syncs nodes for Networked Nodes on spawn to ease midsession join synchronization
func sync_nodes_for_new_player(peer_id: int):
	pause_for_players.rpc()
	syncing[peer_id] = true
	print_verbose("------Begin Sync for Peer %s------" % peer_id)
	
	var net_nodes = get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED))
	
	# Lower number for priority is sync'd first
	net_nodes.sort_custom(func(a: NetworkedNode3D, b: NetworkedNode3D):
		if a.priority_sync_order < b.priority_sync_order:
			if a.networked_id > b.networked_id:
				return 2
			return 1
		return 0
	)
	
	var changed_net_nodes = net_nodes.filter(func(net_node): return net_node.changed)
	begin_sync_with_peer.rpc_id(peer_id, changed_net_nodes.size())
	
	var nodes_sent = 0
	
	for net_node in changed_net_nodes as Array[NetworkedNode3D]:
		if nodes_sent > num_packets_to_incur_wait:
			nodes_sent = 0
			print_verbose("Pausing for %s seconds between sending %s packets" % [seconds_to_wait_between_many_packets, num_packets_to_incur_wait])
			#var pause_begin = Time.get_ticks_msec()
			await get_tree().create_timer(seconds_to_wait_between_many_packets, true).timeout
			#print("Paused for %s miliseconds due to packet amount" % (Time.get_ticks_msec() - pause_begin))
		
		print_verbose("[Syncing Node %s | %s] to [Peer: %s]" % [net_node.priority_sync_order, net_node.p_node.name, peer_id])
		sync_networked_node.rpc_id(peer_id, net_node.networked_id, net_node.SCENE_ID, net_node.get_sync_state().data)
		nodes_sent += 1
	
	sync_game_state.rpc_id(peer_id, GameState.get_sync_state().data)
	NetworkingUtils.sync_id.rpc_id(peer_id, NetworkingUtils.ID)
	print_verbose("-----Finished Sync for Peer %s-----" % peer_id)
	print("[Server Result] %d/%d Nodes needed syncing for %s" % [changed_net_nodes.size(), net_nodes.size(), peer_id])
	
	await get_tree().create_timer(5.0, true).timeout
	if get_tree().paused and syncing[peer_id]:
		syncing[peer_id] = false
		print_debug("Server waited 5 seconds for the client to sync, it never sent the message, disconnecting %s" % peer_id)
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
		if syncing.values().all(func(is_syncing): return not is_syncing):
			print_debug("Fallback unpausing for everyone as the server is no longer syncing")
			unpause_for_players.rpc()

@rpc("any_peer", "reliable")
func begin_sync_with_peer(num_nodes_to_sync: int):
	print("[Peer %s] received request to begin syncing %s nodes" % [multiplayer.get_unique_id(), num_nodes_to_sync])
	total_num_nodes_to_sync = num_nodes_to_sync
	if total_num_nodes_to_sync == 0:
		client_finished_syncing()

@rpc("authority", "reliable")
func sync_game_state(sync_state: PackedByteArray):
	var sync_state_reader : ByteReader = ByteReader.new(sync_state)
	GameState.set_sync_state(sync_state_reader)

@rpc("authority", "reliable")
func sync_networked_node(networked_id: int, net_scene_id: int, sync_state : PackedByteArray):
	var net_nodes = get_tree().get_nodes_in_group(str(NetworkedIds.Scene.NETWORKED))
	var sync_state_reader : ByteReader = ByteReader.new(sync_state)
	print_verbose("[Peer %s] received request to [sync Node %s]" % [multiplayer.get_unique_id(), networked_id])
	var synced = false

	# Sync existing Networked Nodes the Player starts with
	for net_node in net_nodes:
		if net_node.networked_id == networked_id:
			print_verbose("Found existing node ", net_node.p_node.name, " its parent is ", net_node.p_node.get_parent().name)
			net_node.set_sync_state(sync_state_reader)
			synced = true
			num_nodes_syncd += 1
		
	# TODO: this is finally a problem! YAYYY
	# If we didn't find one of the pre-existing nodes we start with, delete it!
	
	# Didn't find the Networked Node, need to spawn one
	if not synced:
		assert(NetworkedScenes.get_scene_by_id(net_scene_id) != null, "%s does not have a NetworkedIds.Scene PATH to instantiate from in SceneIds.gd")
		
		print_verbose("[Peer %s] didn't find %s in the objects on startup. The Player must have generated this at run time. [Spawning a %s with id %s]" \
			% [multiplayer.get_unique_id(), networked_id, NetworkedScenes.get_scene_by_id(net_scene_id).get_state().get_node_name(0), networked_id])
		
		# Spawn Networked Node
		# Add the node into the tree so that it can call get_node from within
		var net_scene = NetworkingUtils.spawn_node(NetworkedScenes.get_scene_by_id(net_scene_id), self)
		var net_node = net_scene.get_node("NetworkedNode3D")
		net_node.networked_id = networked_id
		net_node.set_sync_state(sync_state_reader)
		net_node.changed = true
		num_nodes_syncd += 1
	
	if num_nodes_syncd == total_num_nodes_to_sync:
		print("[Peer %s] finished sync with Server for %s/%s nodes" % [multiplayer.get_unique_id(), num_nodes_syncd, total_num_nodes_to_sync])
		client_finished_syncing()
	elif num_nodes_syncd > total_num_nodes_to_sync:
		print("[Peer %s] is syncing beyond the number of nodes intended %s/%s" % [multiplayer.get_unique_id(), num_nodes_syncd, total_num_nodes_to_sync])

## Client's game state is sync'd at this point
## Sync player specific settings between all clients/server
func client_finished_syncing():
	send_server_sync_finished.rpc_id(GameState.SERVER_ID)
	send_server_my_settings.rpc_id(GameState.SERVER_ID, get_settings_to_send())
	sync_complete.emit()

@rpc("any_peer", "reliable")
func send_server_sync_finished():
	unpause_for_players.rpc(multiplayer.get_remote_sender_id())

## TODO: This should be some kind of PlayerSettings class that handles this and the decoding part
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
