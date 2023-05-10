extends Node
class_name HolderComponent

## The highest parent in the scene for renaming/syncing purposes
@export var true_parent : Node3D

const SCENE_ID = SceneIds.SCENES.HOLDER

func _ready():
	assert(true_parent != null, \
		"Assign a true_parent to this HolderComponent so we can stay sync'd correctly")
	
	name = NetworkingUtils.generate_network_safe_name(name)

	add_to_group(str(SCENE_ID))

func joined_midsession_sync(item_to_hold: Node3D):
	hold_item(item_to_hold)

func is_holding_item() -> bool:
	return get_child_count() > 0

func get_held_item() -> Node3D:
	return get_child(-1)

func hold_item(item: Node3D):
	if not item.is_inside_tree():
		add_child(item, true)
	else:
		item.reparent(self, false)
	item.position = Vector3.ZERO


func _on_interactable_component_interacted(_node : InteractableComponent, player : Player):
	# Player placing Item
	if player.holder_component.is_holding_item():
		# Swap Items - This Holder is currently holding something
		if is_holding_item():
			var curr_item = get_held_item()
			hold_item(player.holder_component.get_held_item())
			player.holder_component.hold_item(curr_item)
		# Take Player's item
		else:
			hold_item(player.holder_component.get_held_item())
	# Player taking Item - Player not holding anything
	elif is_holding_item():
		player.holder_component.hold_item(get_held_item())
