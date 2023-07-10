extends SyncStage
class_name PlayerSyncStage


func _nodes_to_sync() -> Array[Node]:
	var players : Array[Node] = []
	for player in GameState.players.values():
		players.push_back(player)
	return players

func _sync_process(nodes: Array[Node]) -> void:
	var writer = ByteWriter.new()
	
	for player in nodes:
		writer.write_str(player.name)
		writer.append_array(player.get_sync_state().data)
	
	send_client_sync_data(writer.data)

func _receive_sync_data(data: PackedByteArray) -> int:
	var reader = ByteReader.new(data)
	for _data in _nodes_to_sync():
		var player_name = reader.read_str()
		var player = GameState.get_player_by_name(player_name)
		player.set_sync_state(reader)
	
	var writer = ByteWriter.new()
	var client : Player = GameState.get_player_by_id(multiplayer.get_unique_id())
	writer.append_array(client.get_sync_state().data)
	client.notify_peers_of_my_settings.rpc(writer.data)
	
	return total_num_nodes_to_sync
