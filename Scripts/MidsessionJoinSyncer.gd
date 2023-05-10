extends Node

@onready var players = $"../../Players"

## Syncs nodes for HolderComponents. Holders typically just reparent nodes
## Reparenting isn't out of the box supported for the MultiplayerSynchronizer
## So this helps to get things moved along and can be amended for other weirdness
func sync_nodes_for_new_player(peer_id: int):
	print("------Begin Sync for Peer %s------" % peer_id)
	
	
	var holders = get_tree().get_nodes_in_group(str(SceneIds.SCENES.HOLDER))
	
	for holder in holders as Array[HolderComponent]:
		if holder.is_holding_item():
			var holder_name = holder.name
			var holder_scene_id = holder.SCENE_ID
			var held_item_name = holder.get_held_item().name
			var held_item_scene_id = holder.get_held_item().get_node("HoldableComponent").SCENE_ID
			print("[Holder %s] has an item. Sending info to [Peer: %s]" % [holder_name, peer_id])
			# Tell the Peer all the information it needs to get this Holder/Holdable setup
			sync_hold_node.rpc_id(peer_id, holder_name, holder_scene_id, held_item_name, held_item_scene_id)

	NetworkingUtils.sync_id.rpc_id(peer_id, NetworkingUtils.ID)
	print("-----Finished Sync for Peer %s-----" % peer_id)

@rpc("any_peer", "reliable")
func sync_hold_node(holder_name: String, holder_scene_id: int, held_item_name: String, held_item_scene_id: int):
	print("[Peer %s] received request to [sync] for: %s. Holder: %s" % [multiplayer.get_unique_id(), held_item_name, holder_name])
	var synced = false

	# Find the Holdable
	for holdable_scene in get_tree().get_nodes_in_group(str(held_item_scene_id)):
		# Found the Holdable
		if holdable_scene.name == held_item_name:
			# Find the Holder
			for holder in get_tree().get_nodes_in_group(str(holder_scene_id)):
				# Found the Holder
				if holder.name == holder_name:
					(holder as HolderComponent).joined_midsession_sync(holdable_scene)
					synced = true
					break
		
	# Didn't find the Holdable, need to spawn one
	if not synced:
		print("[Peer %s] didn't find %s in the objects on startup. The Player must have generated this at run time. [Spawning a %s with name %s]" \
			% [multiplayer.get_unique_id(), held_item_name, SceneIds.PATHS[held_item_scene_id].get_state().get_node_name(0), held_item_name])
		
		# Spawn Holdable
		var holdable_scene = SceneIds.PATHS[held_item_scene_id].instantiate()
		
		# Find the Holder
		for holder in get_tree().get_nodes_in_group(str(holder_scene_id)):
			# Found the Holder
			if holder.name == holder_name:
				(holder as HolderComponent).joined_midsession_sync(holdable_scene)
				break
		print("About to set Holdable name during sync")
		# _ready should have happened, so set the name after it attempted to generate its own id
		holdable_scene.name = held_item_name
		print("Set Holdable name during sync")
