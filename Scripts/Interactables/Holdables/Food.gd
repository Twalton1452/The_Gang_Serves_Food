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
## Not manually settable right now, auto set to AABB y value
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)
## Offset from the AABB
@export var stacking_spacing_offset = Vector3(0.0, 0.001, 0.0)

@export_category("Scoring")

@export var cook_state_scores : Dictionary = {
	CookState.RAW: 1.0,
	CookState.COOKED: 1.0,
	CookState.BURNED: 0.0,
}

var score : float : get = get_score

func _ready():
	super()
	stacking_spacing = Vector3(0.0, (obj_to_color.get_aabb().size.y * obj_to_color.scale.y), 0.0) + stacking_spacing_offset
#	print(name, " ", obj_to_color.get_aabb().size.y, " ", stacking_spacing)

func get_score() -> float:
	return cook_state_scores.get(cook_state, 0.0)

func _secondary_interact(player: Player):
	# Don't combine off a MultiHolder in the Player's Hand because that could get weird fast
	if player.holder.is_holding_item() and not player.holder.get_held_item() is MultiHolder:
		Combiner.combine(player, self)
	# This food can't combine? Do the standard Holdable thing
	else:
		super(player)
