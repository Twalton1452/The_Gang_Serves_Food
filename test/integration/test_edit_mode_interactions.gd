extends GutTest

var PlayerInteractionsScene = load("res://test/Scenes/test_player_interactions.tscn")

var _interaction_scene = null
var _player : Player = null
var _object : Node3D = null

func pick_up_object() -> void:
	_player.edit_mode_ray_cast.force_raycast_update()
	_player.interact()
	assert_eq(_player.edit_mode_ray_cast.is_holding_editable, true)

func before_each():
	_interaction_scene = PlayerInteractionsScene.instantiate()
	add_child_autoqfree(_interaction_scene)
	_player = _interaction_scene.get_node("Player")
	_player.name = str(GameState.SERVER_ID)
	_player.set_multiplayer_authority(str(_player.name).to_int())
	_object = _interaction_scene.get_node("Object")
	GameState.add_player(_player)
	GameState.hud = double(HUD, DOUBLE_STRATEGY.SCRIPT_ONLY).new()
	GameState.state = GameState.Phase.EDITING_RESTAURANT
	assert_eq(GameState.state, GameState.Phase.EDITING_RESTAURANT, "GameState never switched to EDITING_RESTAURANT")

func test_player_can_pick_up_object() -> void:
	pick_up_object()

func test_player_can_buy_hovering_object() -> void:
	pick_up_object()
	var scene_children_count_start = _interaction_scene.get_children().size()
	_player.buy_attempt()
	await wait_frames(1)
	assert_eq(_interaction_scene.get_children().size(), scene_children_count_start + 1)
	var num_scene = 0
	for child in _interaction_scene.get_children():
		if child.scene_file_path != null and child.scene_file_path == _object.scene_file_path:
			num_scene += 1
	assert_eq(num_scene, 2)

func test_player_can_sell_hovering_object() -> void:
	pick_up_object()
	var scene_children_count_start = _interaction_scene.get_children().size()
	_player.sell_attempt()
	await wait_frames(1)
	assert_eq(_interaction_scene.get_children().size(), scene_children_count_start - 1)
	assert_eq(_player.edit_mode_ray_cast.is_holding_editable, false)

func test_player_can_rotate_held_object() -> void:
	pick_up_object()
	
	assert_eq(_object.global_rotation, Vector3.ZERO)
	_player.rotate_attempt()
	assert_almost_eq(_object.global_rotation, Vector3(0.0, InteractionManager.ROTATION_AMOUNT, 0.0), Vector3(0.1, 0.1, 0.1))

func test_player_can_rotate_targeted_object() -> void:
	assert_eq(_object.global_rotation, Vector3.ZERO)
	_player.edit_mode_ray_cast.force_raycast_update()
	_player.rotate_attempt()
	await wait_frames(1)
	assert_almost_eq(_object.global_rotation, Vector3(0.0, InteractionManager.ROTATION_AMOUNT, 0.0), Vector3(0.1, 0.1, 0.1))

func test_player_can_pick_up_and_place_object() -> void:
	pick_up_object()
	
	_player.camera.rotation.x = deg_to_rad(-25.0)
	await wait_frames(2)
	
	assert_eq(_player.edit_mode_ray_cast.uneditable_ray_cast.is_colliding(), true)
	
	_player.interact()
	await wait_frames(2)
	
	assert_eq(_player.edit_mode_ray_cast.is_holding_editable, false)
	var expected_position = _player.edit_mode_ray_cast.correct_position(_player.edit_mode_ray_cast.uneditable_ray_cast.get_collision_point())
	assert_almost_eq(_object.global_position, expected_position, Vector3(0.1, 0.1, 0.1))

func test_player_can_pick_up_and_release_object_to_original_position() -> void:
	var original_global_position = _object.global_position
	var original_global_rotation = _object.global_rotation
	pick_up_object()
	assert_eq(_player.edit_mode_ray_cast.target_original_position, original_global_position)
	assert_eq(_player.edit_mode_ray_cast.target_original_rotation, original_global_rotation)
	
	_player.camera.rotation.x = deg_to_rad(-25.0)
	_player.global_position += Vector3(0.0, 0.0, -1.0)
	await wait_frames(2)
	
	_object.global_rotation.y += PI / 2
	await wait_frames(1)
	
	assert_eq(_player.edit_mode_ray_cast.uneditable_ray_cast.is_colliding(), true)
	assert_almost_ne(_object.global_position, original_global_position, Vector3(0.1, 0.1, 0.1))
	assert_almost_ne(_object.global_rotation, original_global_rotation, Vector3(0.1, 0.1, 0.1))
	
	_player.secondary_interact()
	await wait_frames(2)
	
	assert_eq(_player.edit_mode_ray_cast.is_holding_editable, false)
	assert_almost_eq(_object.global_position, original_global_position, Vector3(0.1, 0.1, 0.1))
	assert_almost_eq(_object.global_rotation, original_global_rotation, Vector3(0.1, 0.1, 0.1))

func test_player_can_paint_targeted_object() -> void:
	var mesh = _object.get_node("MeshInstance3D")
	var og_color = mesh.get_active_material(0).albedo_color
	var target_color = Color.RED
	_player.edit_mode_ray_cast.force_raycast_update()
	_player.paint_attempt()
	await wait_frames(1)
	assert_eq(mesh.get_active_material(0).albedo_color, target_color)
