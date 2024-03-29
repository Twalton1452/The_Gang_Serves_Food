extends Node
class_name World

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const PORT = 9998
var connected = false

func _ready():
	get_tree().paused = true
	var random_color = Color(randf(),randf(),randf(),1.0)
	$CanvasLayer/MainMenu/MarginContainer/VBoxContainer/ColorPickerButton.color = random_color
	$CanvasLayer/MainMenu/MarginContainer/VBoxContainer/ColorPickerButton.color_changed.emit(random_color)

func _unhandled_input(event):
	if event.is_action_pressed("options"):
		# show menu instead
		#get_tree().quit()
		_on_quit_button_pressed()

func _on_host_button_pressed():
	var enet_peer = ENetMultiplayerPeer.new()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	if OS.has_feature("standalone"):
		upnp_setup()
	
	start_game()

func _on_join_button_pressed():
	var enet_peer = ENetMultiplayerPeer.new()
	
	if OS.has_feature("standalone"):
		enet_peer.create_client(address_entry.text, PORT)
	else:
		enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.server_disconnected.connect(server_disconnect)
	start_game()

func server_disconnect():
	get_tree().quit()

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

func start_game():
	connected = true
	main_menu.hide()
	get_tree().paused = false
	
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	if multiplayer.is_server():
		change_level.call_deferred(load("res://Scenes/restaurant.tscn"))

# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	var level = $Level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	# Add new level.
	level.add_child(scene.instantiate())

func reset_level() -> void:
	reset.rpc()
	change_level.call_deferred(load("res://Scenes/restaurant.tscn"))

# The server can restart the level by pressing Home.
func _input(event):
	if not multiplayer.is_server():
		return
	if event.is_action("ui_home") and Input.is_action_just_pressed("ui_home"):
		reset_level()

func _on_color_picker_button_color_changed(color):
	$CanvasLayer/MainMenu/MeshInstance2D.self_modulate = color
	GameState.player_color = color

func _on_quit_button_pressed():
	get_tree().quit.call_deferred()

@rpc("call_local")
func reset() -> void:
	GameState.reset()
