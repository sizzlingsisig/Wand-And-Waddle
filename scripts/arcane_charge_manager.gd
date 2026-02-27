extends Node
class_name ArcaneChargeManager

@export var stats: Resource
@export_range(0.0, 100.0, 0.1) var starting_charge: float = 0.0
@export var passive_decay_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var decay_speed_multiplier: float = 0.5

var current_charge: float = 0.0
var current_state_name: String = "Depleted"

func _ready() -> void:
	if stats == null:
		stats = load("res://resources/arcane_stats.tres")
	set_charge(starting_charge)

func _physics_process(delta: float) -> void:
	if not passive_decay_enabled:
		return
	if current_charge <= 0.0:
		return

	var profile = get_current_profile()
	var decay_rate := 5.0
	if profile != null:
		decay_rate = profile.passive_decay_rate
	decay_rate *= decay_speed_multiplier

	drain_charge(decay_rate * delta)

func add_charge(amount: float) -> void:
	if amount <= 0.0:
		return
	set_charge(current_charge + amount)

func drain_charge(amount: float) -> void:
	if amount <= 0.0:
		return
	set_charge(current_charge - amount)

func set_charge(value: float) -> void:
	var clamped_charge := clampf(value, 0.0, 100.0)
	clamped_charge = snappedf(clamped_charge, 0.01)
	var resolved_state := _resolve_state_name(clamped_charge)

	var charge_changed := not is_equal_approx(clamped_charge, current_charge)
	var state_changed := resolved_state != current_state_name
	if not charge_changed and not state_changed:
		return

	current_charge = clamped_charge
	current_state_name = resolved_state
	GameEvents.emit_charge_changed(current_charge, current_state_name)

func get_charge_state() -> String:
	return current_state_name

func get_current_charge() -> float:
	return current_charge

func get_current_profile() -> Resource:
	if stats == null:
		return null
	return stats.get_profile_for_charge(current_charge)

func _resolve_state_name(charge_value: float) -> String:
	if stats != null:
		var profile = stats.get_profile_for_charge(charge_value)
		if profile != null:
			return profile.state_name

	if charge_value <= 15.0:
		return "Depleted"
	if charge_value <= 40.0:
		return "Charging"
	if charge_value <= 65.0:
		return "Sweet Spot"
	if charge_value <= 85.0:
		return "Overcharged"
	return "Mana Burn"
