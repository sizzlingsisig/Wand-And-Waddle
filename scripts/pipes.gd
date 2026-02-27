extends Area2D

signal point_earned 

var move_speed: float = 200.0
var has_awarded_point: bool = false

func _process(delta: float) -> void:
	position.x -= move_speed * delta
	if position.x < -100.0:
		queue_free()

func _on_score_area_body_entered(body: Node) -> void:
	if has_awarded_point:
		return
	if body.name == "Player":
		has_awarded_point = true
		point_earned.emit()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		if body.has_method("die"):
			body.die()
