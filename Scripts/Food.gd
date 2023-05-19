extends Cookable
class_name Food

enum CombineRule {
	BOTTOM,
	MIDDLE,
	TOP,
	
	ANYWHERE,
	
}

@export var rule : CombineRule = CombineRule.ANYWHERE

## This class will be the base item that ingredients get combined into
## Example structure for a Burger will be flat and look like:
## - Food
##   - Bottom Bun
##   - Patty
##   - Patty
##   - Cheese
##   - Tomato
##   - Lettuce
##   - Onion
##   - Top Bun
## When an object is "combined" onto this it will assess where it should go
## In the stack given a set of Rules for that particular food
## The lowest child count is on the bottom while the highest child count is on top

func combine_attempt(_food: Food):
	pass

func _secondary_interact(player: Player):
	super(player)