extends Resource
class_name ArcaneStats

@export_range(0.0, 3000.0, 1.0) var base_gravity: float = 1200.0

@export_range(0.0, 100.0, 0.1) var collectible_charge_gain: float = 12.0
@export_range(0.0, 100.0, 0.1) var vent_charge_gain_per_second: float = 30.0
@export_range(0.0, 100.0, 0.1) var water_bucket_charge_loss: float = 20.0
@export_range(0.0, 3000.0, 1.0) var water_bucket_downward_force: float = 500.0

@export_range(0.0, 100.0, 0.1) var orb_cost: float = 10.0
@export_range(0.0, 100.0, 0.1) var burst_cost: float = 100.0

@export_range(0.0, 100.0, 0.1) var flight_transition_charge: float = 50.0
@export var mana_burn_warning_seconds: float = 0.5

@export var state_profiles: Array[ChargeStateProfile] = []

func get_profile_for_charge(charge: float) -> ChargeStateProfile:
	for profile in state_profiles:
		if profile != null and profile.contains_charge(charge):
			return profile
	return null
