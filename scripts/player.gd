extends CharacterBody2D

const WING_SFX = preload("res://assets/flappy-bird-assets-master/audio/wing.ogg")

signal game_started
signal player_died

const PHASE_GROUNDED := "GROUNDED"
const PHASE_FLYING := "FLYING"
const PHASE_GAMEOVER := "GAMEOVER"

var gravity: float = 1200.0
var flap_power: float = -400.0
var is_started: bool = false
var is_dead: bool = false
var current_phase: String = PHASE_GROUNDED
var current_charge_state: String = "Depleted"
var mana_burn_swap_unlock_time_ms: int = 0

@onready var animated_sprite = $AnimatedSprite2D
@onready var charge_manager: Node = get_parent().get_node_or_null("ArcaneChargeManager")

var wing_audio: AudioStreamPlayer

func _ready() -> void:
	wing_audio = AudioStreamPlayer.new()
	wing_audio.stream = WING_SFX
	wing_audio.volume_db = -6.0
	add_child(wing_audio)

	GameEvents.phase_transitioned.connect(_on_phase_transitioned)
	GameEvents.charge_changed.connect(_on_charge_changed)

func _physics_process(delta):
	if is_dead:
		velocity.y += gravity * delta
		animated_sprite.play("explode")
		move_and_slide()
		return

	if not is_started:
		animated_sprite.play("idle")
		if Input.is_action_just_pressed("flap"):
			is_started = true
			velocity.y = flap_power
			animated_sprite.play("dash_up")
			_play_wing_sfx()
			GameEvents.emit_run_started()
			game_started.emit()
		
		return 

	_apply_phase_movement(delta)
	_apply_spells()
	_apply_animation()

	move_and_slide()

func die():
	if not is_dead:
		print("The Goose has crashed!") 
		is_dead = true
		velocity.y = flap_power / 1.5 
		GameEvents.emit_wizard_died()
		player_died.emit()

func _apply_phase_movement(delta: float) -> void:
	var profile := _get_current_profile()
	var mass_multiplier := _get_profile_float(profile, "mass_multiplier", 1.0)
	velocity.y += gravity * mass_multiplier * delta

	if current_phase == PHASE_FLYING:
		_apply_flying_controls(profile)
	else:
		_apply_grounded_controls()

	_apply_charge_side_effects(profile)

func _apply_grounded_controls() -> void:
	if Input.is_action_pressed("ui_down") and is_on_floor():
		animated_sprite.play("lay")
		return

	if Input.is_action_just_pressed("flap"):
		velocity.y = flap_power
		animated_sprite.play("jump")
		_play_wing_sfx()

func _apply_flying_controls(profile: Resource) -> void:
	if not Input.is_action_just_pressed("flap"):
		return

	var swap_inputs := _is_swapped_inputs_active(profile)
	if swap_inputs:
		velocity.y = absf(flap_power) * 0.65
	else:
		velocity.y = flap_power

	animated_sprite.play("dash_up")
	_play_wing_sfx()

func _apply_animation() -> void:
	if animated_sprite.animation == "explode":
		return

	if is_on_floor() and current_phase == PHASE_GROUNDED:
		if Input.is_action_pressed("ui_down"):
			if animated_sprite.animation != "lay":
				animated_sprite.play("lay")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
		return

	if velocity.y > 0.0:
		animated_sprite.play("fall")
	elif animated_sprite.animation != "dash_up" and animated_sprite.animation != "jump":
		animated_sprite.play("dash_up")

func _apply_charge_side_effects(profile: Resource) -> void:
	if profile == null:
		velocity.x = move_toward(velocity.x, 0.0, 20.0)
		return

	var drift_strength := _get_profile_float(profile, "control_drift_strength", 0.0)
	if drift_strength > 0.0 and current_charge_state == "Overcharged":
		var sway := sin(Time.get_ticks_msec() / 240.0)
		velocity.x = sway * 120.0 * drift_strength
	else:
		velocity.x = move_toward(velocity.x, 0.0, 25.0)

func _apply_spells() -> void:
	if not InputMap.has_action("spell_orb") and not InputMap.has_action("spell_burst"):
		return

	if InputMap.has_action("spell_orb") and Input.is_action_just_pressed("spell_orb"):
		_cast_orb()

	if InputMap.has_action("spell_burst") and Input.is_action_just_pressed("spell_burst"):
		_cast_burst()

func _cast_orb() -> void:
	if charge_manager == null or not charge_manager.has_method("drain_charge"):
		return
	var cost := _get_stats_float("orb_cost", 10.0)
	charge_manager.drain_charge(cost)

func _cast_burst() -> void:
	if charge_manager != null and charge_manager.has_method("set_charge"):
		charge_manager.set_charge(0.0)
	velocity.x = 320.0
	velocity.y = minf(velocity.y, flap_power * 0.5)

func _is_swapped_inputs_active(profile: Resource) -> bool:
	if profile == null:
		return false
	var swapped_inputs := bool(profile.get("swapped_inputs"))
	if not swapped_inputs:
		return false
	return Time.get_ticks_msec() >= mana_burn_swap_unlock_time_ms

func _on_phase_transitioned(new_phase: String) -> void:
	current_phase = new_phase

func _on_charge_changed(new_charge: float, state_name: String) -> void:
	var previous_state := current_charge_state
	current_charge_state = state_name
	if previous_state != "Mana Burn" and current_charge_state == "Mana Burn":
		_start_mana_burn_warning()

func _start_mana_burn_warning() -> void:
	var warning_seconds := _get_stats_float("mana_burn_warning_seconds", 0.5)
	mana_burn_swap_unlock_time_ms = Time.get_ticks_msec() + int(warning_seconds * 1000.0)

func _get_current_profile() -> Resource:
	if charge_manager == null or not charge_manager.has_method("get_current_profile"):
		return null
	return charge_manager.get_current_profile()

func _get_stats_float(key: String, fallback: float) -> float:
	if charge_manager == null:
		return fallback
	var stats = charge_manager.get("stats")
	if stats == null:
		return fallback
	var value = stats.get(key)
	if value == null:
		return fallback
	return float(value)

func _get_profile_float(profile: Resource, key: String, fallback: float) -> float:
	if profile == null:
		return fallback
	var value = profile.get(key)
	if value == null:
		return fallback
	return float(value)

func _play_wing_sfx() -> void:
	if wing_audio == null:
		return
	wing_audio.play()
