extends Label

# Assuming the Player is in the same scene, or use a path
@onready var player = $"../../player" 

func _process(delta):
	# Calculate speed (pixels per second) based on velocity length
	var speed = player.velocity.length()
	

	text = "Speed: %.2f u/s" % speed
