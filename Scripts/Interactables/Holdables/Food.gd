extends Cookable
class_name Food

enum CombineRule {
	BASE,
	SUB_BASE,
	INTERMEDIATE,
	SUB_TOP,
	TOP,
	
	# TODO: Ideally an ANYWHERE food combines to the slot the player points at and doesn't follow ordering
	ANYWHERE, 
	
}

@export var rule : CombineRule = CombineRule.ANYWHERE
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)

var score : float : get = get_score

func get_score() -> float:
	if cook_state == CookStates.BURNED:
		return 0.0
	return cook_progress

func _secondary_interact(player: Player):
	# Don't combine off a MultiHolder in the Player's Hand because that could get weird fast
	if player.holder.is_holding_item() and not player.holder.get_held_item() is MultiHolder:
		Combiner.combine(player, self)
	# This food can't combine? Do the standard Holdable thing
	else:
		super(player)
