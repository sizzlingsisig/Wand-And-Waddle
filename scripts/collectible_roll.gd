extends Area2D

@export var move_speed: float = 170.0
@export var fallback_charge_gain: float = 12.0

var charge_manager: Node = null

func setup(manager: Node) -> void:
	charge_manager = manager

func _ready() -> void:
	if charge_manager == null:
		charge_manager = get_parent().get_node_or_null("ArcaneChargeManager")

func _process(delta: float) -> void:
	position.x -= move_speed * delta
	if position.x < -100.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not _is_player_body(body):
		return
	_apply_charge_gain()
	if body is CharacterBody2D:
		body.velocity.y += -120.0
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

func _is_player_body(body: Node) -> bool:
	if body == null:
		return false
	if body.name == "Player":
		return true
	if body.is_in_group("player"):
		return true
	return body is CharacterBody2D
