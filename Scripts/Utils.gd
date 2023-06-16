class_name Utils

## Should be able to delete this when switching to Godot 4.1
## Local to Scene materials are not properly being cleaned up when a node is deleted
## This is a workaround to avoid hundreds of error messages when nodes are deleted
## https://github.com/godotengine/godot/issues/67144#issuecomment-1467005282
static func cleanup_material_overrides(node: Node, mesh_to_clean = null) -> void:
	if not node.is_queued_for_deletion():
		return
	
	var mesh : MeshInstance3D = mesh_to_clean
	if mesh == null:
		mesh = node.get_node_or_null("MeshInstance3D")
	if mesh == null:
		return
	
	for override_index in mesh.get_surface_override_material_count():
		#$MeshInstance3D.set("surface_material_override/0", null)
		mesh.set_surface_override_material(override_index, null)

## Disable colliders for interactables if it is going to be a temporary measure
## Move their collision layer if its a permanent measure
static func disable_nested_colliders_on_interactables_for(node: Node) -> void:
	var multiholder = node if node is MultiHolder else null
	if multiholder != null:
		multiholder.disable_collider()
		multiholder.disable_colliders()
		for item in multiholder.get_held_items():
			if item is CombinedFoodHolder:
				item.disable_held_colliders()
			
			elif item is Food:
				item.disable_collider()
			
			elif item is Drink:
				item.disable_collider()
	else:
		if node is CombinedFoodHolder:
			node.disable_held_colliders()
		
		elif node is Food:
			node.disable_collider()
		
		elif node is Drink:
			node.disable_collider()
