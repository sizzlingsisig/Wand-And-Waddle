extends Resource
class_name ChargeStateProfile

@export var state_name: String = "Sweet Spot"
@export_range(0.0, 100.0, 0.1) var min_charge: float = 41.0
@export_range(0.0, 100.0, 0.1) var max_charge: float = 65.0

@export_range(0.1, 5.0, 0.01) var mass_multiplier: float = 1.0
@export_range(0.0, 1.0, 0.01) var input_lag_seconds: float = 0.0
@export_range(0.0, 1.0, 0.01) var control_drift_strength: float = 0.0
@export var swapped_inputs: bool = false

@export_range(0.0, 50.0, 0.1) var passive_decay_rate: float = 5.0
@export_range(0.0, 2.0, 0.01) var visual_intensity: float = 1.0

func contains_charge(charge: float) -> bool:
	return charge >= min_charge and charge <= max_charge
