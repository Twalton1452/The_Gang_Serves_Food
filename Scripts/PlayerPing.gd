extends MeshInstance3D
class_name PlayerPing

var player_id : int = 0

func _ready():
	var player : Player = GameState.get_player_by_id(player_id)
	get_active_material(0).albedo_color = player.color
	get_active_material(0).albedo_color.a = 0.7
	global_position = find_looking_at_position(player)
	delete_after.call_deferred()

func delete_after(seconds = 1.0) -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", scale * 1.2, seconds / 4.0).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "scale", scale / 1.2, seconds / 2.0 - 0.1).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(seconds, false).timeout
	queue_free()

func find_looking_at_position(player: Player) -> Vector3:
	if player.interact_ray_cast.enabled:
		if player.interact_ray_cast.is_colliding():
			return player.interact_ray_cast.get_collision_point()
	elif player.edit_mode_ray_cast.enabled:
		if player.edit_mode_ray_cast.is_colliding():
			return player.edit_mode_ray_cast.get_collision_point()
		elif player.edit_mode_ray_cast.uneditable_ray_cast.is_colliding():
			return player.edit_mode_ray_cast.uneditable_ray_cast.get_collision_point()
	
	return player.interact_ray_cast.target_position + player.global_position

func _exit_tree():
	Utils.cleanup_material_overrides(self, self)
