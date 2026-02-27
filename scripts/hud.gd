extends CanvasLayer
class_name HUD

## Signal-driven HUD that listens to GameEvents only.
## No direct references to gameplay nodes — pure UI separation of concerns.

@onready var score_label: Label = $HUDPanel/ScoreLabel
@onready var charge_bar: ProgressBar = $HUDPanel/ChargeBar
@onready var charge_value_label: Label = $HUDPanel/ChargeValueLabel
@onready var charge_state_label: Label = $HUDPanel/ChargeStateLabel
@onready var start_overlay: Control = $StartOverlay
@onready var game_over_menu: Control = $GameOverMenu
@onready var final_score_label: Label = $GameOverMenu/Panel/FinalScoreLabel
@onready var high_score_label: Label = $GameOverMenu/Panel/HighScoreLabel

var current_score: int = 0

func _ready() -> void:
	_connect_signals()
	_reset_display()


# ── Signal wiring ──────────────────────────────────────────────

func _connect_signals() -> void:
	GameEvents.score_changed.connect(_on_score_changed)
	GameEvents.charge_changed.connect(_on_charge_changed)
	GameEvents.run_started.connect(_on_run_started)
	GameEvents.wizard_died.connect(_on_wizard_died)


# ── State display ──────────────────────────────────────────────

func _reset_display() -> void:
	start_overlay.visible = true
	game_over_menu.visible = false
	score_label.text = "0"
	charge_bar.value = 0.0
	charge_value_label.text = "0%"
	charge_state_label.text = "Depleted"

func show_start_overlay() -> void:
	start_overlay.visible = true
	game_over_menu.visible = false

func hide_start_overlay() -> void:
	start_overlay.visible = false

func show_game_over(final_score: int, best_score: int) -> void:
	final_score_label.text = "Score: %d" % final_score
	high_score_label.text = "Best: %d" % best_score
	game_over_menu.visible = true


# ── Score display ──────────────────────────────────────────────

func _on_score_changed(new_score: int) -> void:
	current_score = new_score
	_update_score_label()
	_play_score_feedback()

func _update_score_label() -> void:
	score_label.text = str(current_score)


# ── Charge display ─────────────────────────────────────────────

func _on_charge_changed(new_charge: float, state_name: String) -> void:
	var previous_value: float = charge_bar.value
	_update_charge_bar(new_charge, state_name)
	_play_charge_feedback(previous_value, new_charge)

func _update_charge_bar(charge: float, state_name: String) -> void:
	charge_bar.value = charge
	charge_bar.modulate = _get_state_color(state_name)
	charge_value_label.text = "%d%%" % int(round(charge))
	charge_state_label.text = state_name
	charge_state_label.modulate = _get_state_color(state_name)


# ── Signal handlers for game flow ──────────────────────────────

func _on_run_started() -> void:
	hide_start_overlay()

func _on_wizard_died() -> void:
	pass  # game.gd calls show_game_over() after delay

func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()


# ── Visual feedback ────────────────────────────────────────────

func _play_score_feedback() -> void:
	var tween: Tween = create_tween()
	score_label.scale = Vector2(1.0, 1.0)
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

func _play_charge_feedback(previous_charge: float, new_charge: float) -> void:
	var strength: float = clampf(absf(new_charge - previous_charge) / 20.0, 0.25, 1.0)
	var target_scale: Vector2 = Vector2(1.0, 1.0 + (0.15 * strength))
	var tween: Tween = create_tween()
	charge_bar.scale = Vector2(1.0, 1.0)
	tween.tween_property(charge_bar, "scale", target_scale, 0.09)
	tween.tween_property(charge_bar, "scale", Vector2(1.0, 1.0), 0.12)

func _get_state_color(state_name: String) -> Color:
	match state_name:
		"Depleted":
			return Color(0.55, 0.45, 0.7, 0.8)
		"Charging":
			return Color(0.45, 0.55, 1.0, 1.0)
		"Sweet Spot":
			return Color(0.4, 1.0, 0.65, 1.0)
		"Overcharged":
			return Color(1.0, 0.75, 0.2, 1.0)
		"Mana Burn":
			return Color(1.0, 0.3, 0.3, 1.0)
		_:
			return Color(0.75, 0.55, 1.0, 1.0)
