extends Node2D

const POINT_SFX = preload("res://assets/flappy-bird-assets-master/audio/point.ogg")
const HIT_SFX = preload("res://assets/flappy-bird-assets-master/audio/hit.ogg")
const DIE_SFX = preload("res://assets/flappy-bird-assets-master/audio/die.ogg")
const BGM_SFX = preload("res://MXZI, Deno - FAVELA [NCS Release].ogg")

var pipe_scene = preload("res://scenes/pipes.tscn")
var collectible_roll_scene = preload("res://scenes/collectible_roll.tscn")
var score: int = 0
var game_over_handled: bool = false
var current_phase: String = "GROUNDED"
var current_charge: float = 0.0
var current_charge_state: String = "Depleted"

@export var collectible_gap_center_offset: float = 144.0
@export var collectible_x_offset_min: float = -18.0
@export var collectible_x_offset_max: float = 24.0
@export var collectible_y_offset_min: float = -26.0
@export var collectible_y_offset_max: float = 26.0

@onready var score_label = $CanvasLayer/HUDPanel/ScoreLabel
@onready var charge_bar: ProgressBar = $CanvasLayer/HUDPanel/ChargeBar
@onready var charge_value_label = $CanvasLayer/HUDPanel/ChargeValueLabel
@onready var charge_state_label = $CanvasLayer/HUDPanel/ChargeStateLabel
@onready var start_overlay = $CanvasLayer/StartOverlay
@onready var game_over_menu = $CanvasLayer/GameOverMenu
@onready var final_score_label = $CanvasLayer/GameOverMenu/Panel/FinalScoreLabel
@onready var high_score_label = $CanvasLayer/GameOverMenu/Panel/HighScoreLabel
@onready var timer = $Timer
@onready var player = $Player
@onready var charge_manager = $ArcaneChargeManager

var point_audio: AudioStreamPlayer
var hit_audio: AudioStreamPlayer
var die_audio: AudioStreamPlayer
var bgm_audio: AudioStreamPlayer

func _ready() -> void:
	randomize() 
	_setup_audio()
	start_overlay.visible = true
	game_over_menu.visible = false
	score_label.text = "0"
	_update_hud()
	
	player.game_started.connect(_on_game_started)
	player.player_died.connect(_on_player_died)
	GameEvents.wizard_died.connect(_on_wizard_died)
	GameEvents.phase_transitioned.connect(_on_phase_transitioned)
	GameEvents.charge_changed.connect(_on_charge_changed)
	GameEvents.emit_score_changed(score)
	if bgm_audio != null:
		bgm_audio.play()

func _on_game_started() -> void:
	start_overlay.visible = false
	timer.start()

func _on_player_died() -> void:
	_handle_death()

func _on_wizard_died() -> void:
	_handle_death()

func _on_phase_transitioned(new_phase: String) -> void:
	current_phase = new_phase
	print("PHASE -> ", current_phase)
	_update_hud()
	if current_phase == "GAMEOVER":
		_handle_death()

func _on_charge_changed(new_charge: float, state_name: String) -> void:
	var previous_charge := current_charge
	current_charge = new_charge
	current_charge_state = state_name
	print("CHARGE -> ", current_charge, " STATE -> ", current_charge_state)
	_update_hud()
	_play_charge_feedback(previous_charge, current_charge)

func _update_hud() -> void:
	if score_label != null:
		score_label.text = str(score)
	if charge_bar != null:
		charge_bar.value = current_charge
		charge_bar.modulate = _get_state_color(current_charge_state)
	if charge_value_label != null:
		charge_value_label.text = "%d%%" % int(round(current_charge))
	if charge_state_label != null:
		charge_state_label.text = current_charge_state
		charge_state_label.modulate = _get_state_color(current_charge_state)

func _handle_death() -> void:
	if game_over_handled:
		return
	game_over_handled = true

	if hit_audio != null:
		hit_audio.play()
	if die_audio != null:
		die_audio.play()

	timer.stop()
	await get_tree().create_timer(0.8).timeout
	_show_game_over_menu()

# Pipes and collectibles are timer-driven.
func _on_timer_timeout() -> void:
	var new_pipe = pipe_scene.instantiate()
	new_pipe.position = Vector2(600, randf_range(-80, 80))
	new_pipe.point_earned.connect(_on_pipe_point_earned)
	add_child(new_pipe)

	_spawn_collectible_between_pipes(new_pipe.position)

func _spawn_collectible_between_pipes(pipe_position: Vector2) -> void:
	var roll = collectible_roll_scene.instantiate()
	if roll == null:
		return

	var random_x_offset := randf_range(collectible_x_offset_min, collectible_x_offset_max)
	var random_y_offset := randf_range(collectible_y_offset_min, collectible_y_offset_max)

	roll.position = Vector2(
		pipe_position.x + random_x_offset,
		pipe_position.y + collectible_gap_center_offset + random_y_offset
	)
	if roll.has_method("setup"):
		roll.setup(charge_manager)
	add_child(roll)
	
func _on_pipe_point_earned() -> void:
	score += 1
	_update_hud()
	GameEvents.emit_score_changed(score)
	if point_audio != null:
		point_audio.play()
	_play_score_feedback()

func _setup_audio() -> void:
	point_audio = _create_audio_player(POINT_SFX, -5.0)
	hit_audio = _create_audio_player(HIT_SFX, -3.0)
	die_audio = _create_audio_player(DIE_SFX, -2.0)
	bgm_audio = _create_audio_player(BGM_SFX, -18.0)
	if bgm_audio != null:
		bgm_audio.finished.connect(_on_bgm_finished)

func _create_audio_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player_node := AudioStreamPlayer.new()
	player_node.stream = stream
	player_node.volume_db = volume_db
	add_child(player_node)
	return player_node

func _on_bgm_finished() -> void:
	if bgm_audio != null and not game_over_handled:
		bgm_audio.play()

func _show_game_over_menu() -> void:
	if final_score_label != null:
		final_score_label.text = "Score: %d" % score
	if score > Global.high_score:
		Global.high_score = score
	if high_score_label != null:
		high_score_label.text = "Best: %d" % Global.high_score
	if game_over_menu != null:
		game_over_menu.visible = true

func _on_play_again_pressed() -> void:
	get_tree().reload_current_scene()

func _play_score_feedback() -> void:
	if score_label == null:
		return
	var tween := create_tween()
	score_label.scale = Vector2(1.0, 1.0)
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

func _play_charge_feedback(previous_charge: float, new_charge: float) -> void:
	if charge_bar == null:
		return
	var strength := clampf(absf(new_charge - previous_charge) / 20.0, 0.25, 1.0)
	var target_scale := Vector2(1.0, 1.0 + (0.15 * strength))
	var tween := create_tween()
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
