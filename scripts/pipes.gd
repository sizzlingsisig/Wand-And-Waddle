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
	if _is_player_body(body):
		has_awarded_point = true
		point_earned.emit()

func _on_score_area_area_entered(area: Area2D) -> void:
	if has_awarded_point:
		return
	if _is_player_area(area):
		has_awarded_point = true
		point_earned.emit()

func _on_body_entered(body: Node) -> void:
	if _is_player_body(body):
		if body.has_method("die"):
			body.die()

func _on_area_entered(area: Area2D) -> void:
	if not _is_player_area(area):
		return
	var body := area.get_parent()
	if body != null and body.has_method("die"):
		body.die()

func _is_player_body(body: Node) -> bool:
	if body == null:
		return false
	if body.name == "Player":
		return true
	return body.is_in_group("player")

func _is_player_area(area: Area2D) -> bool:
	if area == null:
		return false
	if area.name != "HitArea":
		return false
	var area_parent := area.get_parent()
	return _is_player_body(area_parent)
