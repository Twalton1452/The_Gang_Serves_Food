extends Interactable
class_name TrashCan

func _interact(player: Player) -> void:
	if not player.holder.is_holding_item():
		return
	
	var player_item = player.holder.get_held_item()
	if attempt_to_discard(player_item):
		return
	
	if player_item is MultiHolder or player_item is StackingHolder:
		for held_item in player_item.get_held_items():
			attempt_to_discard(held_item)

func attempt_to_discard(node: Node) -> bool:
	if node_is_throw_awayable(node):
		throw_away(node)
		return true
	
	if node_is_emptyable(node):
		empty_contents(node)
		return true
	
	return false

func node_is_throw_awayable(node: Node) -> bool:
	return node is Food or node is CombinedFoodHolder

func throw_away(node: Node) -> void:
	NetworkingUtils.send_item_for_deletion(node)

func node_is_emptyable(node: Node) -> bool:
	return node.has_method("empty_out")

func empty_contents(node: Node) -> void:
	node.call("empty_out")
