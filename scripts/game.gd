extends Node2D

const POINT_SFX = preload("res://assets/flappy-bird-assets-master/audio/point.ogg")
const HIT_SFX = preload("res://assets/flappy-bird-assets-master/audio/hit.ogg")
const DIE_SFX = preload("res://assets/flappy-bird-assets-master/audio/die.ogg")
const BGM_SFX = preload("res://assets/flappy-bird-assets-master/audio/swoosh.ogg")

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

@onready var score_label = $CanvasLayer/ScoreLabel
@onready var debug_label = $CanvasLayer/DebugLabel
@onready var timer = $Timer
@onready var player = $Player
@onready var charge_manager = $ArcaneChargeManager

var point_audio: AudioStreamPlayer
var hit_audio: AudioStreamPlayer
var die_audio: AudioStreamPlayer
var bgm_audio: AudioStreamPlayer

func _ready():
	randomize() 
	_setup_audio()
	
	player.game_started.connect(_on_game_started)
	player.player_died.connect(_on_player_died)
	GameEvents.wizard_died.connect(_on_wizard_died)
	GameEvents.phase_transitioned.connect(_on_phase_transitioned)
	GameEvents.charge_changed.connect(_on_charge_changed)
	GameEvents.emit_score_changed(score)
	_update_debug_label()
	if bgm_audio != null:
		bgm_audio.play()

func _on_game_started():
	timer.start()

func _on_player_died():
	_handle_death()

func _on_wizard_died():
	_handle_death()

func _on_phase_transitioned(new_phase: String) -> void:
	current_phase = new_phase
	print("PHASE -> ", current_phase)
	_update_debug_label()
	if current_phase == "GAMEOVER":
		_handle_death()

func _on_charge_changed(new_charge: float, state_name: String) -> void:
	current_charge = new_charge
	current_charge_state = state_name
	print("CHARGE -> ", current_charge, " STATE -> ", current_charge_state)
	_update_debug_label()

func _update_debug_label() -> void:
	if debug_label == null:
		return
	debug_label.text = "Phase: %s | Charge: %.1f | State: %s" % [current_phase, current_charge, current_charge_state]

func _handle_death():
	if game_over_handled:
		return
	game_over_handled = true

	if hit_audio != null:
		hit_audio.play()
	if die_audio != null:
		die_audio.play()

	timer.stop()
	
	await get_tree().create_timer(1.5).timeout
	
	get_tree().reload_current_scene()

# Pipes and collectibles are timer-driven.
func _on_timer_timeout():
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
	
func _on_pipe_point_earned():
	score += 1
	score_label.text = str(score)
	GameEvents.emit_score_changed(score)
	if point_audio != null:
		point_audio.play()

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
