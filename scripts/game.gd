extends Node2D

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

func _ready():
	randomize() 
	
	player.game_started.connect(_on_game_started)
	player.player_died.connect(_on_player_died)
	GameEvents.wizard_died.connect(_on_wizard_died)
	GameEvents.phase_transitioned.connect(_on_phase_transitioned)
	GameEvents.charge_changed.connect(_on_charge_changed)
	GameEvents.emit_score_changed(score)
	_update_debug_label()

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
