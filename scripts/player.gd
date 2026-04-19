extends CharacterBody3D

# Parent node for camera and idk.
@onready var eyes: Node3D = $eyes
# The camera.
@onready var camera: Camera3D = $eyes/Node3D/Camera3D
# I dont remember what this is??? I think it's a pivot point for the camera or sumn. idk.
@onready var idk: Node3D = $eyes/Node3D
# the head collider.
# it appears using a cuboid for a head has some side effects, like getting stuck on planes, or anything that can fit in the gap
# between the colliders.
# TODO: fix that ig
@onready var head: CollisionShape3D = $CollisionShape3D2

@onready var FullMesh: MeshInstance3D = $MeshInstance3D
@onready var SlideMesh: MeshInstance3D = $MeshInstance3D2

# Player default speed
const SPEED = 10.0
# Air resistance, ig
const AIR_SLOW_MULT = 2.5
# Friction baby
const GROUND_SLOW_MULT = 1.5
# Y axis velocity while jumping.
const JUMP_VELOCITY = 6.0
# Speed Boost applied to x and z axes when jumping.
const JUMP_SPDBST = 1.5
# Smoothing for Accelaration, applied separately from GROUND_SLOW_MULT (I think?).
const ACCEL_SMOOTH = 5.0
# friction during Sliding. less than Ground, more than Air.
const SLIDE_SLOW = 0.2
# Initial speed boost that the velocity of the x and z axes are multiplied.
const SLIDE_SPDBST = 2.0
# minimum speed while sliding. could use this for crouching.
const SLIDE_MINSPEED = 2.0

# Whether or not the player is sliding. Idk when I'll use this, but nice to have.
var IsSliding = false

# mouse sensitivity.
@export var mouse_sensitivity: float = 0.002

# idk sum mouse shi
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Dont know what I did here to get third person working in a first person-geared thing.
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			eyes.rotate_y(-event.relative.x * mouse_sensitivity)
			idk.rotate_x(-event.relative.y * mouse_sensitivity)
			idk.rotation.x = clamp(idk.rotation.x, deg_to_rad(-50), deg_to_rad(60))

# All the physics calculations.
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("strafe left", "strafe right", "forward", "backward")
	var direction := (eyes.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#Air friction calculation. only occurs while in air. (I think)
	if !is_on_floor():
		velocity.x = lerp(velocity.x, direction.x * SPEED, ACCEL_SMOOTH * delta * (1/AIR_SLOW_MULT))
		velocity.z = lerp(velocity.z, direction.z * SPEED, ACCEL_SMOOTH * delta * (1/AIR_SLOW_MULT))
		IsSliding = false
		
		# Wallrunning.
		# I'm sorry, I had to ask gemini for checking collsiding plane's normal.
#		var collsion = move_and_collide(velocity * delta)
#		if collsion:
#			var normal = collsion.get_normal()
#			var Ref = Vector3.UP
#			var angle = rad_to_deg(normal.angle_to(Ref))
#			print (angle)
#			
#			if angle >= 75 && angle <= 100:
#				print ("Can Wallrun")
			
		
	#All the important stuff is here.
	elif is_on_floor():
		# By default, assumes the player isn't sliding.
		IsSliding = false
		
		# Multiplies velocity by SLIDE_SPDBST when the slide button is intially pressed.
		if Input.is_action_just_pressed("slide"):
			IsSliding = true
			velocity = Vector3(velocity.x * SLIDE_SPDBST, velocity.y, velocity.z * SLIDE_SPDBST)
			
		# Lerps(I think) the velocity to the minimum sliding velocity.
		if Input.is_action_pressed("slide"):
			IsSliding = true
			velocity = velocity.move_toward(Vector3(SLIDE_MINSPEED * direction.x, velocity.y, SLIDE_MINSPEED * direction.z), SLIDE_SLOW)
			
			# Disables the head collider.
			# TODO: add a boolean for sliding (I dont wanna keep checking Input.is_action_pressed)
			head.disabled = true
		
		# If not pressing Slide and there is any direction input at all, 
		# sets velocity to direction into speed for x and z axes, using ACCEL_SMOOTH as delta.
		elif direction.z != 0 && direction.x != 0:
			velocity = velocity.move_toward(Vector3(direction.x * SPEED, direction.y, direction.z * SPEED), ACCEL_SMOOTH)
			
		# If no input in either axes (x or z), uses different method (just lerp) to calculate velocity.
		# Definitely a better way to do this exists, but it's 1:00 and I wanna sleep.
		# also think this messes with the previous elif clause's velocity calculation. possibly. I dont care, movement feels okay.
		# TODO: fix ts 
		else:
			if direction.z == 0:
				velocity.z = lerp(velocity.z, direction.z * SPEED, ACCEL_SMOOTH * delta * GROUND_SLOW_MULT)
			if direction.x == 0:
				velocity.x = lerp(velocity.x, direction.x * SPEED, ACCEL_SMOOTH * delta * GROUND_SLOW_MULT)
				
			# Enables the head collider.
			head.disabled = false
	
	# Jumps if on floor.
	# TODO: rework this for future possibility of double jump and wall jump, maybe use a boolean, idk.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		# Instantly sets y velocity to JUMP_VELOCITY. do I need to change this? idk
		velocity.y = JUMP_VELOCITY
		
		#TODO: findout if this screws with the other calculation.
		velocity.x += direction.x * (SPEED * JUMP_SPDBST)
		velocity.z += direction.z * (SPEED * JUMP_SPDBST)
		
	if IsSliding:
		FullMesh.visible = false
		SlideMesh.visible = true
	else:
		FullMesh.visible = true
		SlideMesh.visible = false
	
	move_and_slide()
	
	if is_on_wall():
		var wall_normal = get_wall_normal()
		var wall_angle = rad_to_deg(wall_normal.angle_to(Vector3.UP))
		print (wall_angle)
		if wall_angle >= 75 && wall_angle <= 100:
			print ("can wallrun")
			velocity = Vector3.ZERO
