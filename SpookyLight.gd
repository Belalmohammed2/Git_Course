extends OmniLight3D

# Configure parameters for the flicker effect
@export var min_energy: float = 0.5
@export var max_energy: float = 2.0
@export var flicker_interval_min: float = 0.05
@export var flicker_interval_max: float = 0.2

var time_passed: float = 0.0
var next_flicker_time: float = 0.0

func _ready() -> void:
	randomize()
	next_flicker_time = randf_range(flicker_interval_min, flicker_interval_max)

func _process(delta: float) -> void:
	time_passed += delta
	
	if time_passed >= next_flicker_time:
		# Randomize energy
		light_energy = randf_range(min_energy, max_energy)
		
		# Reset timer and pick next interval
		time_passed = 0.0
		next_flicker_time = randf_range(flicker_interval_min, flicker_interval_max)
