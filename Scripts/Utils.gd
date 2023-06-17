class_name Utils

const INTERACTABLE_LAYER = 3
const NON_INTERACTABLE_LAYER = 7

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

# WOULD LOVE TO HAVE THESE IN Interactable.gd AS STATIC FUNCTIONS
# BUT LIFE IS TOO COMPLICATED WHEN IT COMES TO THIS GUT TEST RUNNER
# When you're making doubles of classes with static methods it will fail
#   and you have to individually add each static method to an ignore list
#   into the [before_each] Every. Single. Time.
# Easier to just put the static methods in a separate class that fiddle with that bs
# https://github.com/bitwes/Gut/wiki/Doubles#doubling-static-methods

static func enable_from_noninteractable_layer(node: Node) -> void:
	if node is Interactable:
		node.set_collision_layer_value(INTERACTABLE_LAYER, true)
		node.set_collision_layer_value(NON_INTERACTABLE_LAYER, false)
	Interactable.enable_children_from_noninteractable_layer(node)

static func enable_children_from_noninteractable_layer(node: Node) -> void:
	for child in node.get_children():
		if child is Interactable:
			child.set_collision_layer_value(INTERACTABLE_LAYER, true)
			child.set_collision_layer_value(NON_INTERACTABLE_LAYER, false)
		Interactable.enable_children_from_noninteractable_layer(child)

static func remove_from_interactable_layer(node: Node) -> void:
	if node is Interactable:
		node.set_collision_layer_value(INTERACTABLE_LAYER, false)
		node.set_collision_layer_value(NON_INTERACTABLE_LAYER, true)
	Interactable.remove_children_from_interactable_layer(node)

static func remove_children_from_interactable_layer(node: Node) -> void:
	for child in node.get_children():
		if child is Interactable:
			child.set_collision_layer_value(INTERACTABLE_LAYER, false)
			child.set_collision_layer_value(NON_INTERACTABLE_LAYER, true)
		Interactable.remove_children_from_interactable_layer(child)

static func enable_colliders_for(node: Node) -> void:
	if node is Interactable:
		node.enable_collider()
	Interactable.enable_colliders_for_children(node)

static func enable_colliders_for_children(node: Node) -> void:
	for child in node.get_children():
		if child is Interactable:
			child.enable_collider()
		Interactable.enable_colliders_for_children(child)

static func disable_colliders_for(node: Node) -> void:
	if node is Interactable:
		node.disable_collider()
	Interactable.disable_colliders_for_children(node)

static func disable_colliders_for_children(node: Node) -> void:
	for child in node.get_children():
		if child is Interactable:
			child.disable_collider()
		Interactable.disable_colliders_for_children(child)
