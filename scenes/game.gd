extends Node2D

# Make sure this file path exactly matches where your Pipe scene is saved
var pipe_scene = preload("res://scenes/pipes.tscn")

var score: int = 0
@onready var score_label = $CanvasLayer/ScoreLabel

func _ready():
	# Ensures the random number generator creates a different pattern every time you play
	randomize() 

func _on_timer_timeout():
	var new_pipe = pipe_scene.instantiate()
	
	# Position the pipe just off-screen to the right
	new_pipe.position = Vector2(600, randf_range(-80, 80))
	
	# Connect the Pipe's custom signal to the Game script
	# This assumes you added 'signal point_earned' to your pipes.gd script
	new_pipe.point_earned.connect(_on_pipes_point_earned)
	
	add_child(new_pipe)
	
func _on_pipes_point_earned() -> void:
	score += 1
	score_label.text = str(score)
