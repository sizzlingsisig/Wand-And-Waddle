extends Area2D

@export var move_speed: float = 220.0
@export var rotation_speed: float = 7.0

@onready var sprite: Sprite2D = $Sprite2D

func _process(delta: float) -> void:
	position.x -= move_speed * delta
	if sprite != null:
		sprite.rotation += rotation_speed * delta
	if position.x < -120.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" and body.has_method("die"):
		body.die()
