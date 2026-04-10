extends CharacterBody3D

# --- Settings ---
@export_group("Movement")
@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var acceleration: float = 10.0
@export var deceleration: float = 8.0
@export var jump_velocity: float = 4.5

@export_group("Look Settings")
@export var mouse_sensitivity: float = 0.002

var current_speed:float = 0.0
var yaw: float = 0.0
var pitch: float = 0.0
var can_pickup: bool = false

@onready var camera: Camera3D = $Camera3D
@onready var item_placeholder: MeshInstance3D = $Camera3D/ItemPlaceholder
@onready var interact_raycast: RayCast3D = $Camera3D/InteractRaycast
@onready var pickup: Label = $Control/Pickup
@onready var ammo: Label = $Control/ammo
var ammo_amount: int = 10
var bullet: Node3D
var held_item: Node3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Initialize variables with current camera rotation
	yaw = camera.rotation.y
	pitch = camera.rotation.x
	
func hold_item(item: Node3D, item_name: String) -> void:
	var item_copy = item.duplicate()
	bullet = item_copy
	
	bullet.freeze = true
	
	bullet.set_collision_layer_value(1, false)
	bullet.set_collision_layer_value(4, false)
	bullet.set_collision_mask_value(1, false)
	
	item_copy.scale = Vector3(0.5, 0.5, 0.5) # Clean scale setting
	
	camera.add_child(item_copy)
	item_copy.position = item_placeholder.position
	item_copy.rotation = Vector3.ZERO 
	held_item = item_copy
	
	ammo_amount = 10
	ammo.text = item_name.capitalize() + " ammo: " + str(ammo_amount)
	ammo.visible = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -deg_to_rad(89), deg_to_rad(89))
		
		camera.rotation.x = pitch
		camera.rotation.y = yaw

func _physics_process(delta: float) -> void:
	# 1. Handle Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# 3. Handle Movement Direction
	var input_dir: Vector2 = Input.get_vector("wl", "wr", "wf", "wb")
	
	# where "forward" is, since the body no longer rotates.
	var look_direction: Basis = camera.global_transform.basis
	var direction: Vector3 = (look_direction * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Flatten the direction so walking doesn't move you into the floor/air
	direction.y = 0
	direction = direction.normalized()
	
	var is_running: bool = Input.is_action_pressed("run")
	var target_speed: float = run_speed if is_running else walk_speed

	# 4. Physics Logic
	if is_on_floor():
		if direction:
			current_speed = lerp(current_speed, target_speed, delta * acceleration)
		else:
			current_speed = lerp(current_speed, 0.0, delta * deceleration)
		
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Air control
		if direction:
			velocity.x = lerp(velocity.x, direction.x * target_speed, delta * (acceleration * 0.2))
			velocity.z = lerp(velocity.z, direction.z * target_speed, delta * (acceleration * 0.2))

	move_and_slide()
	
	var ray_item: Object = interact_raycast.get_collider()
	if typeof(ray_item) == TYPE_OBJECT and ray_item != null:
		var item_name: String = ray_item.get_meta("name")
		pickup.visible = true
		pickup.text = "Press E to pickup " + item_name.capitalize()
		can_pickup = true
	else:
		pickup.visible = false
		can_pickup = false
		
	if Input.is_action_just_pressed("interact") and can_pickup:
			hold_item(ray_item, ray_item.get_meta("name"))
			ray_item.queue_free()
		
	if Input.is_action_just_pressed("shoot") and ammo_amount > 0 and bullet != null:
			var tmp_bullet = bullet.duplicate()
			get_tree().root.add_child(tmp_bullet)
			
			tmp_bullet.global_transform = bullet.global_transform
			
			tmp_bullet.freeze = false
			tmp_bullet.set_collision_layer_value(1, true)
			tmp_bullet.set_collision_mask_value(1, true)
			tmp_bullet.set_collision_layer_value(16, true) #So can go thru portals
			tmp_bullet.set_collision_mask_value(16, true)
			
			var forward_dir = -camera.global_transform.basis.z
			
			tmp_bullet.apply_central_impulse(forward_dir * 6.0)
			
			ammo_amount -= 1
			ammo.text = tmp_bullet.get_meta("name").capitalize() + " ammo: " + str(ammo_amount)
			
			if ammo_amount <= 0:
				bullet = null
				ammo.visible = false
				held_item.queue_free()
