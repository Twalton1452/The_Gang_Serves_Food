class_name Utils

## Should be able to delete this when switching to Godot 4.1
## Local to Scene materials are not properly being cleaned up when a node is deleted
## This is a workaround to avoid hundreds of error messages when nodes are deleted
## https://github.com/godotengine/godot/issues/67144#issuecomment-1467005282
static func cleanup_material_overrides(node: Node, mesh_to_clean: MeshInstance3D = null) -> void:
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
