extends SyncStage
class_name PlayerSyncStage


static func read_player_sync_data_for(player: Player, reader: ByteReader) -> void:
	var color_vec3 = reader.read_vector3()
	var player_color = Color(color_vec3.x, color_vec3.y, color_vec3.z, 1.0)
	player.set_color(player_color)
#	player.remote_transform.remote_path = reader.read_str()

static func write_player_sync_data_for(player: Player, writer: ByteWriter) -> void:
	writer.write_str(player.name)
	
	var player_color = player.color
	writer.write_vector3(Vector3(player_color.r, player_color.g, player_color.b))
#	writer.write_str(player.remote_transform.remote_path)


func _ready():
	name = "PlayerSyncStage"

func _nodes_to_sync() -> Array[Node]:
	var players : Array[Node] = []
	for player in GameState.players.values():
		players.push_back(player)
	return players

func _sync_process(nodes: Array[Node]) -> void:
	var writer = ByteWriter.new()
	
	for player in nodes:
		PlayerSyncStage.write_player_sync_data_for(player, writer)
	
	send_client_sync_data(writer.data)

func _receive_sync_data(data: PackedByteArray) -> int:
	var reader = ByteReader.new(data)
	for _data in _nodes_to_sync():
		var player = GameState.get_player_by_name(reader.read_str())
		PlayerSyncStage.read_player_sync_data_for(player, reader)
	
	var writer = ByteWriter.new()
	PlayerSyncStage.write_player_sync_data_for(GameState.get_player_by_id(multiplayer.get_unique_id()), writer)
	GameState.notify_peers_of_my_settings.rpc(writer.data)
	
	return total_num_nodes_to_sync
