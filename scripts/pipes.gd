extends Area2D

signal point_earned 

var move_speed: float = 200.0

func _process(delta):
	position.x -= move_speed * delta
	if position.x < -100:
		queue_free()

func _on_score_area_body_entered(body):
	if body.name == "Player":
		point_earned.emit()

func _on_body_entered(body):
	if body.name == "Player":
		if body.has_method("die"):
			body.die()
