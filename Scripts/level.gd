extends Node

@onready var hud = get_node("/root/World/CanvasLayer/HUD")
@onready var health_bar = get_node("/root/World/CanvasLayer/HUD/HealthBar")
@onready var players = $Players
@onready var spawn_point = $SpawnPoint

const player_scene = preload("res://Scenes/player.tscn")

func _ready():
	hud.show()
	# We only need to spawn players on the server.
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(delete_player)

	# Spawn already connected players.
	for id in multiplayer.get_peers():
		add_player(id)

	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server"):
		add_player(1)

func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(delete_player)

func add_player(peer_id: int):
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	player.position = spawn_point.position
	players.add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

	# Attempt to Sync nodes for non-server players
	if peer_id != 1 and multiplayer.get_unique_id() == 1:
		$Networking/MidsessionJoinSyncer.sync_nodes_for_new_player.call_deferred(peer_id)

func delete_player(peer_id):
	var player = players.get_node_or_null(str(peer_id))
	if player != null:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func _on_player_spawner_spawned(node):
	node.position = spawn_point.position
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
