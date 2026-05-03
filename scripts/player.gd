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
const SLIDE_SLOW = 0.4
# Initial speed boost that the velocity of the x and z axes are multiplied by.
const SLIDE_SPDBST = 3.0
# minimum speed while sliding. could use this for crouching.
const SLIDE_MINSPEED = 2.0
# Wallrunning speed multiplier.
const WALLRUN_MULT = 2
# Weight considered when sliding down a slope.
const SLIDE_WEIGHT = 20.0
# Multiplier for weight when sliding up a slope (to slow down).
const UPHILL_WMULT = 2.0

# Whether or not the player is sliding. Idk when I'll use this, but nice to have.
var IsSliding = false

# mouse sensitivity.
@export var mouse_sensitivity: float = 0.002

enum PlayerStates
{
	DEFAULT,
	SLIDING,
	WALLRUNNING
}
var PlayerState = PlayerStates.DEFAULT

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
	velocity += get_gravity() * delta
	if Input.is_action_pressed("slide") && Input.is_action_pressed("jump"):
		print("both pressed")
	
#	PlayerState = PlayerStates.DEFAULT
	var input_dir := Input.get_vector("strafe left", "strafe right", "forward", "backward")
	var direction := (eyes.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#Air friction calculation. only occurs while in air. (I think)
	if !is_on_floor():
		velocity.x = lerp(velocity.x, direction.x * SPEED, ACCEL_SMOOTH * delta * (1/AIR_SLOW_MULT))
		velocity.z = lerp(velocity.z, direction.z * SPEED, ACCEL_SMOOTH * delta * (1/AIR_SLOW_MULT))
		PlayerState = PlayerStates.DEFAULT
		head.disabled = false
		FullMesh.visible = true
		SlideMesh.visible = false

	#All the important stuff is here.
	elif is_on_floor():
		var floor_normal = get_floor_normal()
		PlayerState = PlayerStates.DEFAULT
		if Input.is_action_just_pressed("slide"):
			PlayerState = PlayerStates.SLIDING
			#velocity = Vector3(velocity.x * SLIDE_SPDBST, velocity.y, velocity.z * SLIDE_SPDBST)
			velocity.x *= SLIDE_SPDBST
			velocity.z *= SLIDE_SPDBST
			velocity = velocity.slide(floor_normal).normalized() * velocity.length()
#			velocity = velocity.slide(get_floor_normal()).normalized() * velocity.length()
		elif Input.is_action_pressed("slide"):
			PlayerState = PlayerStates.SLIDING
			
		match PlayerState:
			PlayerStates.DEFAULT:
				head.disabled = false
				FullMesh.visible = true
				SlideMesh.visible = false
				
							
				# If not sliding and there is any direction input at all, 
				# sets velocity to direction into speed for x and z axes, using ACCEL_SMOOTH as delta.
				if direction.z != 0 && direction.x != 0:
					velocity = velocity.move_toward(Vector3(direction.x * SPEED, direction.y, direction.z * SPEED), ACCEL_SMOOTH)

				# If no input in either axes (x or z), uses different method (just lerp) to calculate velocity.
				# Definitely a better way to do this exists, but it's 1:00 and I wanna sleep.
				# TODO: fix ts 
				else:
					if direction.z == 0:
						velocity.z = lerp(velocity.z, direction.z * SPEED, ACCEL_SMOOTH * delta * GROUND_SLOW_MULT)
					if direction.x == 0:
						velocity.x = lerp(velocity.x, direction.x * SPEED, ACCEL_SMOOTH * delta * GROUND_SLOW_MULT)
						
				# TODO: rework this for future possibility of double jump and wall jump, maybe use a boolean, idk.
				if Input.is_action_just_pressed("jump"):
					# Instantly sets y velocity to JUMP_VELOCITY. do I need to change this? idk
					velocity.y = JUMP_VELOCITY
					
					#TODO: findout if this screws with the other calculation.
					velocity.x += direction.x * (SPEED * JUMP_SPDBST)
					velocity.z += direction.z * (SPEED * JUMP_SPDBST)
			PlayerStates.SLIDING:
				# this part is from AI :(
				var slope_dir = Vector3.DOWN.slide(floor_normal).normalized()
				var move_dot_slope = velocity.dot(slope_dir)
				if floor_normal.y < 0.99:
					var steepness = 1.0 - floor_normal.y
					if move_dot_slope > 0:
						velocity += slope_dir * steepness * SPEED * delta * SLIDE_WEIGHT
					else:
						velocity += slope_dir * steepness * SPEED * delta * SLIDE_WEIGHT * UPHILL_WMULT
				else:
					velocity = velocity.move_toward(Vector3(SLIDE_MINSPEED * direction.x, velocity.y, SLIDE_MINSPEED * direction.z), SLIDE_SLOW)
				FullMesh.visible = false
				SlideMesh.visible = true
				head.disabled = true
				
				# TODO: rework this for future possibility of double jump and wall jump, maybe use a boolean, idk.
				if Input.is_action_just_pressed("jump"):
					head.disabled = false
					FullMesh.visible = true
					SlideMesh.visible = false
					PlayerState = PlayerStates.DEFAULT
					# Instantly sets y velocity to JUMP_VELOCITY. do I need to change this? idk
					velocity.y = JUMP_VELOCITY
					
					#TODO: findout if this screws with the other calculation.
					velocity.x += direction.x * (SPEED * JUMP_SPDBST)
					velocity.z += direction.z * (SPEED * JUMP_SPDBST)

	
	move_and_slide()
	
#	if is_on_wall():
#		var wall_normal = get_wall_normal()
#		var wall_angle = rad_to_deg(wall_normal.angle_to(Vector3.UP))
		
#		var flat_wallN = Vector3(wall_normal.x, 0, wall_normal.z).normalized()
#		var flat_LookDir = Vector3(-global_transform.basis.z.x, 0, -global_transform.basis.z.z).normalized()
		
#		var angle_diff = flat_wallN.signed_angle_to(flat_LookDir, Vector3.UP)
#		var LookMult = 0
#		if input_dir.y > 0:
#			LookMult = -1
#		elif input_dir.y < 0:
#			LookMult = 1
#		print ("LookMult: ",LookMult)
#		print ("wall_angle: ", wall_angle)
#		print("angle_diff: ", angle_diff)
#		print ("flat wallN: ", flat_wallN)
#		print ("flat LookDir: ", flat_LookDir)
#		if wall_angle >= 75 && wall_angle <= 100:
#			print ("can wallrun")
#			print (wall_normal)
#			var rotatedNormal = wall_normal.rotated(Vector3.UP, deg_to_rad(90)).normalized()
#			velocity = rotatedNormal * SPEED * WALLRUN_MULT
#			print (velocity)
			
			# need to rework ENTIRE movement system to use state machines. highly inefficient to do everything like this.
