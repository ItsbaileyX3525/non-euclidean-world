extends CharacterBody3D

# --- Settings ---
@export_group("Movement")
@export var walk_speed := 5.0
@export var run_speed := 8.0
@export var acceleration := 10.0
@export var deceleration := 8.0
@export var jump_velocity := 4.5

@export_group("Look Settings")
@export var mouse_sensitivity := 0.002

# --- Variables ---
var current_speed := 0.0
var yaw := 0.0
var pitch := 0.0

@onready var camera = $Camera3D 

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Initialize variables with current camera rotation
	yaw = camera.rotation.y
	pitch = camera.rotation.x

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -deg_to_rad(89), deg_to_rad(89))
		
		# Apply BOTH rotations ONLY to the camera
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
	var input_dir := Input.get_vector("wl", "wr", "wf", "wb")
	
	# IMPORTANT: We now use camera.global_transform.basis to determine 
	# where "forward" is, since the body no longer rotates.
	var look_direction = camera.global_transform.basis
	var direction = (look_direction * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Flatten the direction so walking doesn't move you into the floor/air
	direction.y = 0
	direction = direction.normalized()
	
	var is_running = Input.is_action_pressed("run")
	var target_speed = run_speed if is_running else walk_speed

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
