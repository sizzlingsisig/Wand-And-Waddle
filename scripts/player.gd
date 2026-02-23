extends CharacterBody2D

var gravity: float = 1200.0
var flap_power: float = -400.0

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# 1. Apply Gravity
	velocity.y += gravity * delta

	# 2. Handle Flap (Dash Up)
	if Input.is_action_just_pressed("flap"):
		velocity.y = flap_power
		animated_sprite.play("dash_up")

	move_and_slide()
	
	# 3. Handle Transitions (Fall and Idle)
	# If we are NOT currently playing the dash animation (let it finish or wait until falling)
	if animated_sprite.animation != "dash_up" or velocity.y > 0:
		
		if is_on_floor():
			# If touching the ground, we are idle
			animated_sprite.play("idle")
		elif velocity.y > 0:
			# If in the air and falling down, play fall animation
			animated_sprite.play("fall")
