extends RayCast3D
class_name EditModeRayCast

## Class for when the player is trying to edit the layout of their restaurant
## Reliant on a specific architecture for the Editable Scenes
## - Collision Layer 1
## Tree format:
## - MeshInstance3D
##   - StaticBody3D

## The top level node of what the raycast found to move around
@onready var remote_transform : RemoteTransform3D = $RemoteTransform3D
## Raycast for pointing at the ground to create a snapping effect
@onready var uneditable_ray_cast : RayCast3D = $UneditableRayCast3D
@onready var audio_player : AudioStreamPlayer3D = $AudioStreamPlayer3D

# Should extract this to a parent class alongside the highlight code in InteractRay
var outline_material : StandardMaterial3D = preload("res://Materials/Grow_Outline_mat.tres")
var looking_at : Node3D = null
var looking_at_top_y : float = 0.0
var should_snap_to_looking_at_y = false

## The collider the ray points to
var target : StaticBody3D = null
var target_original_position = Vector3.ZERO
var target_original_rotation = Vector3.ZERO
var default_snap = Vector3(0.05, 0.05, 0.05)
var snapping = Vector3(0.1, 0.1, 0.1)
var is_holding_editable : bool : get = get_is_holding_editable

func set_sync_state(reader: ByteReader) -> void:
	remote_transform.remote_path = reader.read_str()
	
	var has_target = reader.read_bool()
	if has_target:
		lock_on_to(get_node(reader.read_path_to()))
		target_original_position = reader.read_vector3()
		target_original_rotation = reader.read_vector3()

func get_sync_state(writer: ByteWriter) -> void:
	writer.write_str(remote_transform.remote_path)
	
	var has_target = target != null
	writer.write_bool(has_target)
	if has_target:
		writer.write_path_to(target)
		writer.write_vector3(target_original_position)
		writer.write_vector3(target_original_rotation)

func get_is_holding_editable() -> bool:
	return remote_transform.remote_path != ^""

func get_held_editable_path() -> NodePath:
	return remote_transform.remote_path

func get_held_editable_node() -> Node:
	return get_node_or_null(get_held_editable_path())

## Maybe restrictions in the future
func can_place_node() -> bool:
	return true

## Called from InteractionManager
func lock_on_to(node: Node) -> void:
	target_original_position = node.owner.global_position
	target_original_rotation = node.owner.global_rotation
	remote_transform.global_position = node.owner.global_position
	remote_transform.remote_path = node.owner.get_path()
	target = node
#	set_child_collisions_for(node.owner, false)
	add_exception(target)
	
	var grouper : NetworkedGrouperNode3D = Utils.crawl_up_for_grouper_node(node)
	if grouper != null:
		snapping = grouper.snapping_spacing
		should_snap_to_looking_at_y = grouper.y_independant_snapping
#	audio_player.play()

func unlock_from_target() -> void:
	remote_transform.remote_path = ^""
	remote_transform.position = Vector3.ZERO
	remote_transform.rotation = Vector3.ZERO
	snapping = default_snap
	
	if looking_at != null:
		hide_outline(looking_at)
		looking_at = null
	
	clear_exceptions()
	if target == null or target.is_queued_for_deletion():
		return
#	set_child_collisions_for(target.owner, true)
	target = null
#	audio_player.play()

func release_target_to_original_orientation() -> void:
	var releasing_node = get_held_editable_node()
	unlock_from_target()
	releasing_node.global_position = target_original_position
	releasing_node.global_rotation = target_original_rotation

func set_child_collisions_for(node: Node3D, value: bool) -> void:
	node.propagate_call("set_collision_layer_value", [1, value], true)

func enable():
	enabled = true
	uneditable_ray_cast.enabled = true
	snapping = default_snap

func disable():
	enabled = false
	uneditable_ray_cast.enabled = false
	if looking_at:
		hide_outline(looking_at)
		looking_at = null
	remote_transform.remote_path = ^""

func _unhandled_input(event):
	if event.is_action_pressed("ui_left"):
		enabled = !enabled
		if looking_at:
			hide_outline(looking_at)

func _physics_process(_delta):
	if not enabled:
		return
	
	# Changed targets
	if looking_at != get_collider():
		
		# Reset the previous target
		if looking_at != null:
			hide_outline(looking_at)
			# Show the outline for the new target
			if get_collider() != null:
				show_outline(get_collider())
				looking_at_top_y = calculate_the_top_y_value_of(get_collider().get_parent())
		# Previous target was nothing
		else:
			show_outline(get_collider())
			looking_at_top_y = calculate_the_top_y_value_of(get_collider().get_parent())
		looking_at = get_collider()
	
	if not is_holding_editable:
		return
	
	if is_colliding():
		remote_transform.global_position = correct_position(get_collision_point())
		if not should_snap_to_looking_at_y:
			remote_transform.global_position.y = snapped(get_collision_point().y, looking_at_top_y)
	elif uneditable_ray_cast.is_colliding():
		remote_transform.global_position = correct_position(uneditable_ray_cast.get_collision_point())
	else:
		remote_transform.position = Vector3(snapping.x, 0.0, snapping.z - 1.5)
		remote_transform.global_position.y = snapping.y

func correct_position(pos: Vector3) -> Vector3:
	return pos.snapped(snapping)

func calculate_the_top_y_value_of(collided_object: Node) -> float:
	if not collided_object is MeshInstance3D:
		return 0.0
	var aabb = collided_object.get_aabb()
	return aabb.position.y + aabb.size.y * collided_object.scale.y

func calculate_the_top_end_values_of(collided_object: Node) -> Vector3:
	if not collided_object is MeshInstance3D:
		return Vector3.ZERO
	var aabb = collided_object.get_aabb()
	return aabb.position + aabb.size * collided_object.scale

func set_material_overlay_for_children(node: Node3D, material: StandardMaterial3D, _transparency : float):
	for child in node.get_children():
		if child is MeshInstance3D:
			child.material_overlay = material
		if child is Node3D:
			set_material_overlay_for_children(child, material, _transparency)

func show_outline(node: Node3D):
	set_material_overlay_for_children(node.owner, outline_material, 0.2)

func hide_outline(node: Node3D):
	set_material_overlay_for_children(node.owner, null, 0.0)
