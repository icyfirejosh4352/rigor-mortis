extends CharacterBody3D

@onready var eyes: Node3D = $eyes
@onready var camera: Camera3D = $eyes/Camera3D

const SPEED = 10.0
const JUMP_VELOCITY = 4.5
const JUMP_SPDBST = 1.5
const ACCEL_SMOOTH = 5.0

@export var mouse_sensitivity: float = 0.002

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			eyes.rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-50), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# movement rework
	var input_dir := Input.get_vector("strafe left", "strafe right", "forward", "backward")
	var direction := (eyes.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity.x = lerp(velocity.x, direction.x * SPEED, ACCEL_SMOOTH * delta)
	velocity.z = lerp(velocity.z, direction.z * SPEED, ACCEL_SMOOTH * delta)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		velocity.x = direction.x * (SPEED * JUMP_SPDBST)
		velocity.z = direction.z * (SPEED * JUMP_SPDBST)
	
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
#	var input_dir := Input.get_vector("strafe left", "strafe right", "forward", "backward")
#	var direction := (eyes.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
#	if direction:
#		velocity.x = direction.x * SPEED
#		velocity.z = direction.z * SPEED
#	else:
#		velocity.x = move_toward(velocity.x, 0, SPEED)
#		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
