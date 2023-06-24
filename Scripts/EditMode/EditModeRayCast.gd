extends RayCast3D
class_name EditModeRayCast

## The top level node of what the raycast found to move around
@onready var remote_transform : RemoteTransform3D = $RemoteTransform3D
## Raycast for pointing at the ground to create a snapping effect
@onready var uneditable_ray_cast : RayCast3D = $UneditableRayCast3D

# Should extract this to a parent class alongside the highlight code in InteractRay
var outline_material : StandardMaterial3D = preload("res://Materials/Grow_Outline_mat.tres")
var looking_at : Node3D = null
var looking_at_top_y : float = 0.0

## The collider the ray points to
var target : StaticBody3D = null
var default_snap = Vector3(0.05, 0.05, 0.05)
var snapping = Vector3(0.1, 0.1, 0.1)
var is_holding_editable : bool : get = get_is_holding_editable

func set_sync_state(reader: ByteReader) -> void:
	remote_transform.remote_path = reader.read_str()
	
	var has_target = reader.read_bool()
	if has_target:
		lock_on_to(get_node(reader.read_path_to()))

func get_sync_state() -> ByteWriter:
	var writer = ByteWriter.new()
	writer.write_str(remote_transform.remote_path)
	
	var has_target = target != null
	writer.write_bool(has_target)
	if has_target:
		writer.write_path_to(target)
	
	return writer

func get_is_holding_editable() -> bool:
	return remote_transform.remote_path != ^""

func get_held_editable_path() -> NodePath:
	return remote_transform.remote_path

func get_held_editable_node() -> Node:
	return get_node_or_null(get_held_editable_path())


## Called from InteractionManager
func lock_on_to(node: Node) -> void:
	remote_transform.global_position = node.owner.global_position
	remote_transform.remote_path = node.owner.get_path()
	target = node
	set_child_collisions_for(node.owner, false)
	if node.owner.get_parent() is NetworkedGrouperNode3D:
		snapping = (node.owner.get_parent() as NetworkedGrouperNode3D).snapping_spacing

func unlock_from_target() -> void:
	remote_transform.remote_path = ^""
	remote_transform.position = Vector3.ZERO
	snapping = default_snap
	
	if looking_at:
		hide_outline(looking_at)
	looking_at = null
	
	if target == null or target.is_queued_for_deletion():
		return
	
	set_child_collisions_for(target.owner, true)
	target = null

func set_child_collisions_for(node: Node3D, value: bool) -> void:
	node.propagate_call("set_collision_layer_value", [1, value], true)
#	for child in node.get_children():
#		if child is StaticBody3D:
#			child.set_collision_layer_value(1, value)
#		set_child_collisions_for(child, value)

func enable():
	enabled = true
	uneditable_ray_cast.enabled = true
	snapping = default_snap

func disable():
	enabled = false
	uneditable_ray_cast.enabled = false
	if looking_at:
		hide_outline(looking_at)
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
		if looking_at:
			hide_outline(looking_at)
			# Show the outline for the new target
			if get_collider() != null:
				show_outline(get_collider())
				var collided_object = get_collider().get_parent()
				if collided_object is MeshInstance3D:
					var aabb = collided_object.get_aabb()
					var object_top_y = aabb.position.y + aabb.size.y * collided_object.scale.y
					looking_at_top_y = object_top_y
		# Previous target was nothing
		else:
			show_outline(get_collider())
			
		looking_at = get_collider()
	
	if not is_holding_editable:
		return
	
	if is_colliding():
		remote_transform.global_position = Vector3(get_collision_point().x, looking_at_top_y, get_collision_point().z).snapped(snapping)
	elif uneditable_ray_cast.is_colliding():
		remote_transform.global_position = uneditable_ray_cast.get_collision_point().snapped(snapping)
	else:
		remote_transform.position = Vector3(0.0, 0.0, -1.5)
		remote_transform.global_position.y = 0.0

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
