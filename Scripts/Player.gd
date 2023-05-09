extends CharacterBody3D
class_name Player

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var gun_ray_cast = $Camera3D/GunRayCast3D
@onready var interact_ray_cast = $Camera3D/InteractRayCast3D
@onready var item_holder = $Camera3D/ItemHolder

const SPEED = 4.0
const JUMP_VELOCITY = 10.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
# var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity = 20.0
var look_speed = .005
var health = 3

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	if event.is_action_pressed("unlock_cursor"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * look_speed)
		camera.rotate_x(-event.relative.y * look_speed)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	if event.is_action_pressed("shoot") and anim_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		if gun_ray_cast.is_colliding():
			var hit_player = gun_ray_cast.get_collider()
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
	if event.is_action_pressed("interact"):
		if interact_ray_cast.is_colliding():
			var interactable = interact_ray_cast.get_collider() as InteractableComponent
			interactable.interact.rpc(get_multiplayer_authority())
			

func _physics_process(delta):
	if not is_multiplayer_authority(): return

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
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

func is_holding_item():
	return item_holder.get_child_count() > 0

func hold_item(item: Node3D):
	print("%s is now holding %s" % [str(get_multiplayer_authority()), item.name])
	item.reparent(item_holder, false)
	item.position = Vector3.ZERO
