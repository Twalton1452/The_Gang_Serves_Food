extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var players = $Players

const player_scene = preload("res://Scenes/player.tscn")
const PORT = 9998
var enet_peer = ENetMultiplayerPeer.new()

#func _ready():
	#call_deferred("_on_host_button_pressed")

func _unhandled_input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	# upnp_setup()

func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	# enet_peer.create_client(address_entry.text, PORT)
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.server_disconnected.connect(server_disconnect)

func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(remove_player)

func add_player(peer_id: int):
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	players.add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

	# Attempt to Sync nodes for non-server players
	if peer_id != 1 and multiplayer.get_unique_id() == 1:
		$Networking/MidsessionJoinSyncer.sync_nodes_for_new_player.call_deferred(peer_id)

func remove_player(peer_id):
	var player = players.get_node_or_null(str(peer_id))
	if player != null:
		player.queue_free()

func server_disconnect():
	get_tree().quit()

func update_health_bar(health_value):
	health_bar.value = health_value

# clients see this signal when they are spawned
# hook up any necessary client signals here
func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())
	
	
	
	
	
	
	
