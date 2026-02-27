extends CharacterBody2D

signal game_started
signal player_died

var gravity: float = 1200.0
var flap_power: float = -400.0
var is_started: bool = false
var is_dead: bool = false

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta):
	if not is_started:
		animated_sprite.play("idle")
		if Input.is_action_just_pressed("flap"):
			is_started = true
			velocity.y = flap_power
			animated_sprite.play("dash_up")
			GameEvents.emit_run_started()
			game_started.emit()
		
		return 

	velocity.y += gravity * delta

	if not is_dead:
		if Input.is_action_just_pressed("flap"):
			velocity.y = flap_power
			animated_sprite.play("dash_up")

		if animated_sprite.animation != "dash_up" or velocity.y > 0:
			if is_on_floor():
				animated_sprite.play("idle")
			elif velocity.y > 0:
				animated_sprite.play("fall")
				
	else:
		animated_sprite.play("explode") 

	move_and_slide()

func die():
	if not is_dead:
		print("The Goose has crashed!") 
		is_dead = true
		velocity.y = flap_power / 1.5 
		GameEvents.emit_wizard_died()
		player_died.emit()
