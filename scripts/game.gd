extends Node2D

## Main game orchestrator.
## Uses enum FSM for core game states: IDLE → PLAYING → GAMEOVER.
## Delegates all HUD display to the HUD scene via GameEvents signals.

# ── Enum FSM ───────────────────────────────────────────────────

enum GameState { IDLE, PLAYING, GAMEOVER }

var state: GameState = GameState.IDLE

# ── Audio constants ────────────────────────────────────────────

const POINT_SFX: AudioStream = preload("res://assets/flappy-bird-assets-master/audio/point.ogg")
const HIT_SFX: AudioStream = preload("res://assets/flappy-bird-assets-master/audio/hit.ogg")
const DIE_SFX: AudioStream = preload("res://assets/flappy-bird-assets-master/audio/die.ogg")
const BGM_SFX: AudioStream = preload("res://MXZI, Deno - FAVELA [NCS Release].ogg")

# ── Scene preloads ─────────────────────────────────────────────

var pipe_scene: PackedScene = preload("res://scenes/pipes.tscn")
var collectible_roll_scene: PackedScene = preload("res://scenes/collectible_roll.tscn")

# ── Game data ──────────────────────────────────────────────────

var score: int = 0

# ── Collectible spawn tuning ───────────────────────────────────

@export var collectible_gap_center_offset: float = 144.0
@export var collectible_x_offset_min: float = -18.0
@export var collectible_x_offset_max: float = 24.0
@export var collectible_y_offset_min: float = -26.0
@export var collectible_y_offset_max: float = 26.0

# ── Node references ────────────────────────────────────────────

@onready var timer: Timer = $Timer
@onready var player: CharacterBody2D = $Player
@onready var charge_manager: ArcaneChargeManager = $ArcaneChargeManager
@onready var hud: HUD = $HUD

# ── Audio players ──────────────────────────────────────────────

var point_audio: AudioStreamPlayer
var hit_audio: AudioStreamPlayer
var die_audio: AudioStreamPlayer
var bgm_audio: AudioStreamPlayer


# ── Lifecycle ──────────────────────────────────────────────────

func _ready() -> void:
	randomize()
	_setup_audio()
	_transition_to(GameState.IDLE)

	player.game_started.connect(_on_game_started)
	player.player_died.connect(_on_player_died)
	GameEvents.wizard_died.connect(_on_wizard_died)

	GameEvents.emit_score_changed(score)

	if bgm_audio != null:
		bgm_audio.play()


# ── State transitions ─────────────────────────────────────────

func _transition_to(new_state: GameState) -> void:
	if state == new_state:
		return
	state = new_state

	match state:
		GameState.IDLE:
			_enter_idle()
		GameState.PLAYING:
			_enter_playing()
		GameState.GAMEOVER:
			_enter_gameover()

func _enter_idle() -> void:
	score = 0
	timer.stop()
	hud.show_start_overlay()

func _enter_playing() -> void:
	hud.hide_start_overlay()
	timer.start()

func _enter_gameover() -> void:
	timer.stop()
	_play_death_sfx()
	await get_tree().create_timer(0.8).timeout
	_update_high_score()
	hud.show_game_over(score, Global.high_score)


# ── Signal handlers ────────────────────────────────────────────

func _on_game_started() -> void:
	if state == GameState.IDLE:
		_transition_to(GameState.PLAYING)

func _on_player_died() -> void:
	if state == GameState.PLAYING:
		_transition_to(GameState.GAMEOVER)

func _on_wizard_died() -> void:
	if state == GameState.PLAYING:
		_transition_to(GameState.GAMEOVER)


# ── Spawning ───────────────────────────────────────────────────

func _on_timer_timeout() -> void:
	if state != GameState.PLAYING:
		return
	_spawn_pipe()

func _spawn_pipe() -> void:
	var new_pipe: Area2D = pipe_scene.instantiate() as Area2D
	new_pipe.position = Vector2(600.0, randf_range(-80.0, 80.0))
	new_pipe.point_earned.connect(_on_pipe_point_earned)
	add_child(new_pipe)
	_spawn_collectible_near(new_pipe.position)

func _spawn_collectible_near(pipe_position: Vector2) -> void:
	var roll: Node2D = collectible_roll_scene.instantiate() as Node2D
	if roll == null:
		return

	var offset_x: float = randf_range(collectible_x_offset_min, collectible_x_offset_max)
	var offset_y: float = randf_range(collectible_y_offset_min, collectible_y_offset_max)

	roll.position = Vector2(
		pipe_position.x + offset_x,
		pipe_position.y + collectible_gap_center_offset + offset_y
	)
	if roll.has_method("setup"):
		roll.setup(charge_manager)
	add_child(roll)


# ── Scoring ────────────────────────────────────────────────────

func _on_pipe_point_earned() -> void:
	if state != GameState.PLAYING:
		return
	score += 1
	GameEvents.emit_score_changed(score)
	_play_point_sfx()

func _update_high_score() -> void:
	if score > Global.high_score:
		Global.high_score = score


# ── Audio helpers ──────────────────────────────────────────────

func _setup_audio() -> void:
	point_audio = _create_audio_player(POINT_SFX, -5.0)
	hit_audio = _create_audio_player(HIT_SFX, -3.0)
	die_audio = _create_audio_player(DIE_SFX, -2.0)
	bgm_audio = _create_audio_player(BGM_SFX, -18.0)
	if bgm_audio != null:
		bgm_audio.finished.connect(_on_bgm_finished)

func _create_audio_player(stream: AudioStream, volume_db: float) -> AudioStreamPlayer:
	var player_node: AudioStreamPlayer = AudioStreamPlayer.new()
	player_node.stream = stream
	player_node.volume_db = volume_db
	add_child(player_node)
	return player_node

func _play_point_sfx() -> void:
	if point_audio != null:
		point_audio.play()

func _play_death_sfx() -> void:
	if hit_audio != null:
		hit_audio.play()
	if die_audio != null:
		die_audio.play()

func _on_bgm_finished() -> void:
	if bgm_audio != null and state != GameState.GAMEOVER:
		bgm_audio.play()

