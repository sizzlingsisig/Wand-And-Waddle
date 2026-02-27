extends Node
class_name GameStateMachine

enum GamePhase {
	GROUNDED,
	FLYING,
	GAMEOVER,
}

@export_range(0.0, 100.0, 0.1) var flight_transition_charge: float = 50.0

var current_phase: GamePhase = GamePhase.GROUNDED
var has_initialized: bool = false

func _ready() -> void:
	GameEvents.charge_changed.connect(_on_charge_changed)
	GameEvents.wizard_died.connect(_on_wizard_died)
	_transition_to(GamePhase.GROUNDED)

func get_phase() -> GamePhase:
	return current_phase

func is_grounded() -> bool:
	return current_phase == GamePhase.GROUNDED

func is_flying() -> bool:
	return current_phase == GamePhase.FLYING

func is_gameover() -> bool:
	return current_phase == GamePhase.GAMEOVER

func _on_charge_changed(current_charge: float, _state_name: String) -> void:
	if current_phase != GamePhase.GROUNDED:
		return
	if current_charge >= flight_transition_charge:
		_transition_to(GamePhase.FLYING)

func _on_wizard_died() -> void:
	_transition_to(GamePhase.GAMEOVER)

func _transition_to(new_phase: GamePhase) -> void:
	if has_initialized and current_phase == new_phase:
		return
	current_phase = new_phase
	has_initialized = true
	GameEvents.emit_phase_transitioned(get_phase_name(current_phase))

func get_phase_name(phase: GamePhase) -> String:
	match phase:
		GamePhase.GROUNDED:
			return "GROUNDED"
		GamePhase.FLYING:
			return "FLYING"
		GamePhase.GAMEOVER:
			return "GAMEOVER"
		_:
			return "GROUNDED"
