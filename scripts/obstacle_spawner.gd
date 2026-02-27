extends Node

signal point_earned

const PHASE_GROUNDED := "GROUNDED"
const PHASE_FLYING := "FLYING"
const PHASE_GAMEOVER := "GAMEOVER"

@export var grounded_obstacle_scene: PackedScene = preload("res://scenes/rolling_teacup.tscn")
@export var flying_obstacle_scene: PackedScene = preload("res://scenes/pipes.tscn")
@export var spawn_interval_seconds: float = 2.0
@export var spawn_x: float = 620.0
@export var grounded_spawn_y_min: float = 230.0
@export var grounded_spawn_y_max: float = 282.0
@export var flying_spawn_y_min: float = -80.0
@export var flying_spawn_y_max: float = 80.0
@export var flying_safe_buffer_seconds: float = 3.0

var is_active: bool = false
var current_phase: String = PHASE_GROUNDED
var spawn_cooldown: float = 0.0
var flying_safe_until_ms: int = 0

func _ready() -> void:
	GameEvents.phase_transitioned.connect(_on_phase_transitioned)

func _process(delta: float) -> void:
	if not is_active:
		return
	if current_phase == PHASE_GAMEOVER:
		return
	if current_phase == PHASE_FLYING and Time.get_ticks_msec() < flying_safe_until_ms:
		return

	spawn_cooldown -= delta
	if spawn_cooldown > 0.0:
		return

	_spawn_obstacle()
	spawn_cooldown = spawn_interval_seconds

func start_spawning() -> void:
	is_active = true
	spawn_cooldown = 0.0

func stop_spawning() -> void:
	is_active = false

func _spawn_obstacle() -> void:
	var scene_to_spawn := grounded_obstacle_scene
	if current_phase == PHASE_FLYING:
		scene_to_spawn = flying_obstacle_scene

	if scene_to_spawn == null:
		return

	var obstacle = scene_to_spawn.instantiate()
	if obstacle == null:
		return

	if obstacle is Node2D:
		obstacle.position = Vector2(spawn_x, _resolve_spawn_y())

	if obstacle.has_signal("point_earned"):
		obstacle.point_earned.connect(_on_obstacle_point_earned)

	get_parent().add_child(obstacle)

func _resolve_spawn_y() -> float:
	if current_phase == PHASE_FLYING:
		return randf_range(flying_spawn_y_min, flying_spawn_y_max)
	return randf_range(grounded_spawn_y_min, grounded_spawn_y_max)

func _on_phase_transitioned(new_phase: String) -> void:
	current_phase = new_phase
	if current_phase == PHASE_FLYING:
		flying_safe_until_ms = Time.get_ticks_msec() + int(flying_safe_buffer_seconds * 1000.0)

func _on_obstacle_point_earned() -> void:
	point_earned.emit()
