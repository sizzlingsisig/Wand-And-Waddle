extends CharacterBody2D

var gravity: float = 1200.0
var flap_power: float = -400.0

func _physics_process(delta):
	velocity.y += gravity * delta

	if Input.is_action_just_pressed("flap"):
		velocity.y = flap_power

	move_and_slide()
