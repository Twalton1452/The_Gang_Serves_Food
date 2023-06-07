extends CharacterBody3D
class_name Player

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var gun_ray_cast = $Camera3D/GunRayCast3D
@onready var interact_ray_cast = $Camera3D/InteractRayCast3D
@onready var pixel_face : PixelFace = $PixelFace
@onready var holder : Holder = $Camera3D/Holder


const SPEED = 4.0
const JUMP_VELOCITY = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
# var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity = 20.0
var look_speed = .005
var health = 3

# Settings
var color : Color = Color.WHITE

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

# Remove when upgrading to 4.1
# Work around for getting errors when deleting a player
# https://github.com/godotengine/godot/issues/67144#issuecomment-1467005282
func _exit_tree(): # When someone calls queue_free() here
	$MeshInstance3D.set("surface_material_override/0", null)

func _ready():
	if not is_multiplayer_authority(): return

	init.call_deferred()

func init():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	pixel_face.random_expression()
	pick_emotive_face.rpc(pixel_face.frame)

func set_color(col: Color):
	color = col
	$MeshInstance3D.get_active_material(0).albedo_color = color

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
	if event.is_action_pressed("secondary_interact"):
		if interact_ray_cast.is_colliding():
			secondary_interact()
			

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
