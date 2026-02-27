extends Area2D

@export var move_speed: float = 170.0
@export var fallback_charge_gain: float = 12.0

var charge_manager: Node = null

func setup(manager: Node) -> void:
	charge_manager = manager

func _process(delta: float) -> void:
	position.x -= move_speed * delta
	if position.x < -100.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.name != "Player":
		return
	_apply_charge_gain()
	queue_free()

func _apply_charge_gain() -> void:
	if charge_manager == null:
		return
	if not charge_manager.has_method("add_charge"):
		return

	var gain := fallback_charge_gain
	var stats = charge_manager.get("stats")
	if stats != null:
		var configured_gain = stats.get("collectible_charge_gain")
		if configured_gain != null:
			gain = float(configured_gain)

	charge_manager.add_charge(gain)
