extends OmniLight3D

@export_category("Flicker Settings")
@export var min_energy: float = 0.5
@export var max_energy: float = 1.5
@export var noise_speed: float = 10.0
@export var flicker_strength: float = 0.5

var time_passed: float = 0.0
var base_energy: float = 0.0
var noise = FastNoiseLite.new()

func _ready() -> void:
	# Store the initial energy as the baseline
	base_energy = light_energy
	
	# Configure noise for a natural flicker effect
	noise.seed = randi()
	noise.frequency = 2.0
	noise.fractal_octaves = 2

func _process(delta: float) -> void:
	time_passed += delta * noise_speed
	
	# Sample noise and map it to a -1 to 1 range
	var noise_value = noise.get_noise_1d(time_passed)
	
	# Calculate new energy
	# We linearly interpolate between min and max based on the noise
	# Remap noise (-1 to 1) to (0 to 1) for lerp weight
	var weight = (noise_value + 1.0) / 2.0
	
	var target_energy = lerp(min_energy, max_energy, weight)
	
	# Apply final energy
	light_energy = target_energy
