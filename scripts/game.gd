extends Node2D

var pipe_scene = preload("res://scenes/pipes.tscn")
var score: int = 0

@onready var score_label = $CanvasLayer/ScoreLabel
@onready var timer = $Timer
@onready var player = $Player # Make sure this matches your player node name

func _ready():
	randomize() 
	
	# Connect the Player's signals to this Game script
	player.game_started.connect(_on_game_started)
	player.player_died.connect(_on_player_died)

# ---------------------------------------------------------
# GAME FLOW FUNCTIONS
# ---------------------------------------------------------

func _on_game_started():
	# The player flapped for the first time! Start sending pipes.
	timer.start()

func _on_player_died():
	# Stop the pipes from spawning
	timer.stop()
	
	# Stop any pipes currently on screen from moving
	# (We do this by pausing the whole tree, but leaving the player active to fall)
	# For a simple version, we just wait and restart:
	
	# Wait for 1.5 seconds so the player can see the goose fall
	await get_tree().create_timer(1.5).timeout
	
	# Now reload the scene
	get_tree().reload_current_scene()

# ---------------------------------------------------------
# PIPE SPAWNING & SCORING
# ---------------------------------------------------------

func _on_timer_timeout():
	var new_pipe = pipe_scene.instantiate()
	new_pipe.position = Vector2(600, randf_range(-80, 80))
	new_pipe.point_earned.connect(_on_pipe_point_earned)
	add_child(new_pipe)
	
func _on_pipe_point_earned():
	score += 1
	score_label.text = str(score)
