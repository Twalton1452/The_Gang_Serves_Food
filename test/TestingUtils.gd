extends GutTest
class_name TestingUtils

func create_multiholder(how_many_holders: int) -> MultiHolder:
	var multi_holder = MultiHolder.new()
	for i in how_many_holders:
		var holder = Holder.new()
		holder.name = "Holder" + str(i)
		multi_holder.add_child(holder)
		autofree(holder)
	autofree(multi_holder)
	return multi_holder

func create_combined_food(ids: Array[SceneIds.SCENES]) -> CombinedFoodHolder:
	var combined_food_holder = CombinedFoodHolder.new()
	autofree(combined_food_holder)
	
	for id in ids:
		var item = SceneIds.get_scene_from_id(id).instantiate()
		combined_food_holder.hold_item(autoqfree(item))
	
	return combined_food_holder
