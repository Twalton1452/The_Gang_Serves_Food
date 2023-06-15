extends GutTest
class_name TestingUtils

func create_multiholder(how_many_holders: int) -> MultiHolder:
	var multi_holder = MultiHolder.new()
	multi_holder.name = "MultiHolder"
	
	var holders : Array[Holder] = []
	for i in range(how_many_holders):
		var holder = Holder.new()
		holder.name = "Holder" + str(i)
		multi_holder.add_child(holder)
		autoqfree(holder)
		
		# add CollisionShape3D so the Interactable is_enabled == true
		var collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		collision_shape.disabled = false
		holder.collider = collision_shape
		holder.add_child(collision_shape)
		autoqfree(collision_shape)
		holders.push_back(holder)
		
	add_child_autoqfree(multi_holder)
	return multi_holder

func create_combined_food(ids: Array[NetworkedIds.Scene]) -> CombinedFoodHolder:
	var combined_food_holder = CombinedFoodHolder.new()
	combined_food_holder.name = "CombinedFoodHolder"
	autoqfree(combined_food_holder)
	
	for id in ids:
		var item = NetworkedScenes.get_scene_by_id(id).instantiate()
		combined_food_holder.hold_item(autoqfree(item))
	
	return combined_food_holder
