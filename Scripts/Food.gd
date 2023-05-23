extends Cookable
class_name Food

enum CombineRule {
	BASE,
	SUB_BASE,
	INTERMEDIATE,
	SUB_TOP,
	TOP,
	
	ANYWHERE,
	
}

@export var rule : CombineRule = CombineRule.ANYWHERE
@export var stacking_spacing = Vector3(0.0, 0.008, 0.0)
