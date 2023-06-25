extends CharacterBody3D
class_name Player

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var gun_ray_cast = $Camera3D/GunRayCast3D
@onready var interact_ray_cast = $Camera3D/InteractRayCast3D
@onready var edit_mode_ray_cast : EditModeRayCast = $Camera3D/EditModeRayCast3D
@onready var pixel_face : PixelFace = $PixelFace
@onready var holder : Holder = $Camera3D/Holder
@onready var interact_holder : Holder = $Camera3D/Holder
@onready var client_side_holder_node : Node3D = $Camera3D/ClientSideHolderPosition

const WORLD_MASK = 1
const SPEED = 4.0
const JUMP_VELOCITY = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
# var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity = 20.0
var look_speed = .005
var health = 3

# Settings
var color : Color = Color.WHITE : set = set_color, get = get_color

func set_sync_state(reader: ByteReader) -> void:
	color = reader.read_color()
	pixel_face.frame = reader.read_int()
	edit_mode_ray_cast.set_sync_state(reader)

func get_sync_state() -> ByteWriter:
	var writer = ByteWriter.new()
	writer.write_color(color)
	writer.write_int(pixel_face.frame)
	writer.append_array(edit_mode_ray_cast.get_sync_state().data)
	return writer

## Called from PlayerSyncStage
@rpc("any_peer", "call_remote")
func notify_peers_of_my_settings(data: PackedByteArray) -> void:
	var reader = ByteReader.new(data)
	set_sync_state(reader)

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

# Remove when upgrading to 4.1
# Work around for getting errors when deleting a player
# https://github.com/godotengine/godot/issues/67144#issuecomment-1467005282
func _exit_tree(): # When someone calls queue_free() here
	Utils.cleanup_material_overrides(self)

func _ready():
	# Do this for every player so that the player's Holder gets switched easily
	GameState.state_changed.connect(_on_game_state_changed)
	_on_game_state_changed()
	
	if not is_multiplayer_authority(): return

	init.call_deferred()

func init():
	if not is_multiplayer_authority(): return
	holder.position = client_side_holder_node.position
	holder.rotation = client_side_holder_node.rotation
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	pixel_face.random_expression()
	pick_emotive_face.rpc(pixel_face.frame)

func _on_game_state_changed() -> void:
	if GameState.state == GameState.Phase.EDITING_RESTAURANT:
		set_collision_mask_value(WORLD_MASK, false)
		switch_to_edit_mode_hand()
	elif GameState.state == GameState.Phase.OPEN_FOR_BUSINESS:
		set_collision_mask_value(WORLD_MASK, true)
		switch_to_interactable_hand()

func switch_to_interactable_hand() -> void:
	# TODO: can't switch back to OPEN_FOR_BUSINESS if player is holding anything
	if holder.is_holding_item():
		await holder.released_item
	
	interact_ray_cast.enabled = true
	edit_mode_ray_cast.disable()

func switch_to_edit_mode_hand() -> void:
	# TODO: can't switch back to OPEN_FOR_BUSINESS if player is holding anything
	if holder.is_holding_item():
		await holder.released_item
	
	interact_ray_cast.enabled = false
	edit_mode_ray_cast.enable()

func get_color() -> Color:
	if is_multiplayer_authority():
		return GameState.player_color
	return $MeshInstance3D.get_active_material(0).albedo_color

func set_color(col: Color):
	color = col
	$MeshInstance3D.get_active_material(0).albedo_color = col

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	# Only used to exit the game currently
	if event.is_action_pressed("unlock_cursor"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * look_speed)
		camera.rotate_x(-event.relative.y * look_speed)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	# Left over example code from Boilerplate
	if event.is_action_pressed("shoot") and anim_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		if gun_ray_cast.is_colliding():
			var hit_player = gun_ray_cast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())

	if event.is_action_pressed("interact"):
		if interact_ray_cast.is_colliding():
			interact()
		elif edit_mode_ray_cast.is_holding_editable:
			edit_mode_place()
		elif edit_mode_ray_cast.is_colliding():
			edit_mode_interact()
	if event.is_action_pressed("secondary_interact"):
		if interact_ray_cast.is_colliding():
			secondary_interact()
		elif edit_mode_ray_cast.is_holding_editable:
			edit_mode_secondary_interact()
	if event.is_action_pressed("buy"):
		buy_attempt()
	elif event.is_action_pressed("sell"):
		sell_attempt()

func _physics_process(delta):
	if not is_multiplayer_authority(): return

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		pixel_face.random_expression()
		pick_emotive_face.rpc(pixel_face.frame)

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if anim_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")
		

	move_and_slide()
	if position.y < -30.0:
		position = get_node("../../SpawnPoint").position

func interact() -> void:
	var interactable = interact_ray_cast.get_collider() as Interactable
	InteractionManager.attempt_interaction(self, interactable, InteractionManager.InteractionType.PRIMARY)
	#interactable.interact(self)

func secondary_interact() -> void:
	var interactable = interact_ray_cast.get_collider() as Interactable
	InteractionManager.attempt_interaction(self, interactable, InteractionManager.InteractionType.SECONDARY)
	#interactable.secondary_interact(self)

func edit_mode_interact():
	var node = edit_mode_ray_cast.get_collider() as StaticBody3D
	InteractionManager.attempt_edit_mode_interaction(self, node, InteractionManager.InteractionType.PRIMARY)

func edit_mode_secondary_interact():
	InteractionManager.attempt_edit_mode_secondary_interaction(self)

func edit_mode_place():
	InteractionManager.attempt_edit_mode_placement(self)

func buy_attempt():
	if not edit_mode_ray_cast.is_holding_editable:
		return
	
	var node = edit_mode_ray_cast.get_held_editable_node()
	if node.scene_file_path.is_empty():
		return
	
	InteractionManager.buy_attempt()

func sell_attempt():
	if not edit_mode_ray_cast.is_holding_editable:
		return
	
	var node = edit_mode_ray_cast.get_held_editable_node()
	if node.scene_file_path.is_empty():
		return
	
	InteractionManager.sell_attempt()

@rpc("call_local")
func pick_emotive_face(id: int):
	pixel_face.change_expression_to(id)

## Left over example code from boilerplate
@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("any_peer")
func receive_damage():
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")
