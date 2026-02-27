extends Area2D

signal point_earned # This is the "shout" the Game script is listening for

var move_speed: float = 200.0

func _process(delta):
	position.x -= move_speed * delta
	if position.x < -100:
		queue_free()

func _on_score_area_body_entered(body):
	if body.name == "Player":
		point_earned.emit() # This triggers the _on_pipe_point_earned in Game.gd

func _on_body_entered(body):
	if body.name == "Player":
		# Instead of reloading the scene, we trigger the function we just made
		if body.has_method("die"):
			body.die()
