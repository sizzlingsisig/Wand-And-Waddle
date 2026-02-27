extends CharacterBody2D

signal game_started
signal player_died

var gravity: float = 1200.0
var flap_power: float = -400.0
var is_started: bool = false
var is_dead: bool = false

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	# State 1: The "Get Ready" Hover
	if not is_started:
		animated_sprite.play("idle")
		if Input.is_action_just_pressed("flap"):
			is_started = true
			velocity.y = flap_power
			animated_sprite.play("dash_up")
			game_started.emit()
		
		# The return statement stops the engine from reading the gravity code below
		return 

	# Apply gravity constantly once the game has started, even if dead
	velocity.y += gravity * delta

	# State 2: Alive and Active
	if not is_dead:
		if Input.is_action_just_pressed("flap"):
			velocity.y = flap_power
			animated_sprite.play("dash_up")

		# Handle Animation Transitions
		if animated_sprite.animation != "dash_up" or velocity.y > 0:
			if is_on_floor():
				animated_sprite.play("idle")
			elif velocity.y > 0:
				animated_sprite.play("fall")
				
	# State 3: Dead and Falling
	else:
		animated_sprite.play("explode") 

	move_and_slide()

# A custom function that your pipes will call to trigger the crash
func die():
	if not is_dead:
		print("The Goose has crashed!") # Watch for this in the Output window!
		is_dead = true
		velocity.y = flap_power / 1.5 
		player_died.emit()
