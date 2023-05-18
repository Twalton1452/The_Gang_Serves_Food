class_name FoodCombiner
static func combine(resting: Cookable, in_hand: Cookable):
	if resting.scene_file_path == in_hand.scene_file_path:
		in_hand.reparent(resting, false)
		in_hand.position = resting.get_child(-1).position + Vector3(0.0, 0.006, 0.0)
