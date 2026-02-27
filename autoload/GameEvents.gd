extends Node

signal charge_changed(current_charge: float, state_name: String)
signal wizard_died()
signal score_changed(new_score: int)
signal phase_transitioned(new_phase: String)

func emit_charge_changed(current_charge: float, state_name: String) -> void:
	charge_changed.emit(current_charge, state_name)

func emit_wizard_died() -> void:
	wizard_died.emit()

func emit_score_changed(new_score: int) -> void:
	score_changed.emit(new_score)

func emit_phase_transitioned(new_phase: String) -> void:
	phase_transitioned.emit(new_phase)
