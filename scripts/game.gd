extends Node2D

var pipe_scene = preload("res://scenes/pipes.tscn")
var score: int = 0
var game_over_handled: bool = false

@onready var score_label = $CanvasLayer/ScoreLabel
@onready var timer = $Timer
@onready var player = $Player

func _ready():
	randomize() 
	
	player.game_started.connect(_on_game_started)
	player.player_died.connect(_on_player_died)
	GameEvents.wizard_died.connect(_on_wizard_died)
	GameEvents.emit_score_changed(score)

func _on_game_started():
	timer.start()

func _on_player_died():
	_handle_death()

func _on_wizard_died():
	_handle_death()

func _handle_death():
	if game_over_handled:
		return
	game_over_handled = true

	timer.stop()
	
	await get_tree().create_timer(1.5).timeout
	
	get_tree().reload_current_scene()

# Pipe Spawning and Scoring Logic
func _on_timer_timeout():
	var new_pipe = pipe_scene.instantiate()
	new_pipe.position = Vector2(600, randf_range(-80, 80))
	new_pipe.point_earned.connect(_on_pipe_point_earned)
	add_child(new_pipe)
	
func _on_pipe_point_earned():
	score += 1
	score_label.text = str(score)
	GameEvents.emit_score_changed(score)
