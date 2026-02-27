extends Node
class_name GameStateMachine

const PHASE_GROUNDED := "GROUNDED"
const PHASE_FLYING := "FLYING"
const PHASE_GAMEOVER := "GAMEOVER"

@export_range(0.0, 100.0, 0.1) var flight_transition_charge: float = 50.0

var current_phase: String = PHASE_GROUNDED

func _ready() -> void:
	GameEvents.charge_changed.connect(_on_charge_changed)
	GameEvents.wizard_died.connect(_on_wizard_died)
	_transition_to(PHASE_GROUNDED)

func get_phase() -> String:
	return current_phase

func is_grounded() -> bool:
	return current_phase == PHASE_GROUNDED

func is_flying() -> bool:
	return current_phase == PHASE_FLYING

func is_gameover() -> bool:
	return current_phase == PHASE_GAMEOVER

func _on_charge_changed(current_charge: float, _state_name: String) -> void:
	if current_phase != PHASE_GROUNDED:
		return
	if current_charge >= flight_transition_charge:
		_transition_to(PHASE_FLYING)

func _on_wizard_died() -> void:
	_transition_to(PHASE_GAMEOVER)

func _transition_to(new_phase: String) -> void:
	if current_phase == new_phase:
		return
	current_phase = new_phase
	GameEvents.emit_phase_transitioned(current_phase)
