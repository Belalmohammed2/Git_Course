extends Node3D

# HAUNTED MIRROR SCRIPT
# No reflection. Just shadows and fear.

@export_group("Settings")
@export var scare_enabled: bool = true
@export var scare_cooldown: float = 5.0 # Time lights are OFF
@export var scare_sound: AudioStream = preload("res://assets/sounds/four_voices_whispering.mp3")
@export var blackout_duration: float = 2.0 # Time screen is DARK
@export var look_threshold: float = 0.8 
@export var activation_distance: float = 2.0 # How close you must be
@export var blackout_opacity: float = 0.75 # How dark (0.0=Clear, 1.0=Black)

@export_group("Nodes")
@export var mirror_mesh: MeshInstance3D
@export var blackout_canvas: CanvasLayer
@export var blackout_rect: ColorRect
@export var dark_figures: Array[Node3D] # Drag your scary models here!

var _scare_triggered: bool = false
var _stored_lights: Dictionary = {} 
var _audio_player: AudioStreamPlayer

func _ready():
	_find_nodes()
	_setup_audio()
	_setup_haunted_material()
	
	if dark_figures.size() == 0:
		print("Mirror Warning: No Dark Figures assigned in Inspector!")

func _setup_audio():
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)

func _find_nodes():
	if not blackout_canvas: blackout_canvas = find_child("BlackoutCanvas", true, false)
	if blackout_canvas and not blackout_rect: blackout_rect = blackout_canvas.find_child("ColorRect", true, false)
	
	if not mirror_mesh:
		var all_meshes = find_children("*", "MeshInstance3D", true, false)
		for mesh in all_meshes:
			var m_name = mesh.name.to_lower()
			if "mirror" in m_name or "glass" in m_name:
				mirror_mesh = mesh
				break
		if not mirror_mesh and all_meshes.size() > 0: mirror_mesh = all_meshes[0]

func _setup_haunted_material():
	if not mirror_mesh: return
	
	# Create a spooky Noise Shader
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode unshaded;

	uniform sampler2D noise_tex;
	uniform float speed = 0.1;

	void fragment() {
		// Scrolling UVs
		vec2 uv1 = UV + vec2(time * speed, time * speed * 0.5);
		vec2 uv2 = UV - vec2(time * speed * 0.7, time * speed * 0.2);
		
		float n1 = texture(noise_tex, uv1).r;
		float n2 = texture(noise_tex, uv2).r;
		
		float final_noise = (n1 + n2) * 0.5;
		
		// Map noise to Dark Grey -> Black
		vec3 color = mix(vec3(0.0), vec3(0.1, 0.1, 0.1), final_noise);
		
		ALBEDO = color;
	}
	""".replace("time", "TIME")
	
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	
	var noise = FastNoiseLite.new()
	noise.frequency = 0.02
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.seamless = true
	
	shader_mat.set_shader_parameter("noise_tex", noise_tex)
	shader_mat.set_shader_parameter("speed", 0.1)
	
	mirror_mesh.material_override = shader_mat

func _process(_delta):
	# SCARE LOGIC
	if scare_enabled and not _scare_triggered:
		check_player_looking()

func check_player_looking():
	var main_cam = get_viewport().get_camera_3d()
	if not main_cam or not mirror_mesh: return
	
	var to_mirror_vec = mirror_mesh.global_position - main_cam.global_position
	var dist = to_mirror_vec.length()
	
	if dist > activation_distance: return

	var look_dir = -main_cam.global_transform.basis.z
	var to_mirror_dir = to_mirror_vec.normalized()
	
	var dot = look_dir.dot(to_mirror_dir)
	# print("Mirror Debug: Dist: ", dist, " Angle: ", dot)
	
	if dot > look_threshold:
		trigger_scare()

# ---------------------------------------------------------
# SCARE SEQUENCE
# ---------------------------------------------------------
func trigger_scare():
	print("Mirror: SCARE SEQUENCE STARTED")
	
	if dark_figures.size() == 0:
		printerr("Mirror Error: No dark figures assigned!")
	
	_scare_triggered = true
	
	# 1. Lock Camera (Player turns to face invisible target)
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("lock_camera") and dark_figures.size() > 0:
		player.lock_camera(dark_figures[0])
	
	if player and player.has_method("update_objective"):
		print("Mirror: Calling update_objective")
		player.update_objective("Find the key")
	else:
		print("Mirror: Player or update_objective not found")
	
	# 2. Wait for camera to rotate (1.2 seconds)
	await get_tree().create_timer(1.2).timeout
	
	# 3. REVEAL! (Lights out + Figures + Sound + Flash)
	if _audio_player and scare_sound:
		_audio_player.stream = scare_sound
		_audio_player.play()
		
	# Blackout Overlay
	if blackout_canvas:
		blackout_canvas.visible = true
		if blackout_rect:
			blackout_rect.color = Color(0, 0, 0, blackout_opacity)
	
	# Dim Scene Lights
	var root = get_tree().current_scene
	_find_and_dim_lights(root)

	# Show Figures + Play Anim + Light Flash
	var scare_light = _create_scare_light(dark_figures[0].global_position if dark_figures.size() > 0 else global_position)
	scare_light.visible = true
	
	for figure in dark_figures:
		if figure:
			figure.visible = true
			var anim = figure.find_child("AnimationPlayer", true, false)
			if anim and anim.has_animation("Old Man Idle/mixamo_com"):
				anim.play("Old Man Idle/mixamo_com")
			elif anim and anim.has_animation("Old Man Idle"): # Fallback
				anim.play("Old Man Idle")
	
	# 4. Wait Scare Duration (5s)
	await get_tree().create_timer(scare_cooldown).timeout
	
	# 5. RESTORE
	restore_lights()
	if scare_light: scare_light.queue_free() # Remove light
	
	# Hide Figures
	for figure in dark_figures:
		if figure: figure.visible = false
		
	# Unlock Camera
	if player and player.has_method("unlock_camera"):
		player.unlock_camera()

	if blackout_canvas:
		blackout_canvas.visible = false
	print("Mirror: Normalize.")

func _create_scare_light(pos: Vector3) -> OmniLight3D:
	var light = OmniLight3D.new()
	add_child(light)
	light.global_position = pos + Vector3(0, 1.0, 0.5) # Slightly above/front
	light.light_color = Color(0.8, 0.1, 0.1) # Reddish
	light.light_energy = 2.0
	light.omni_range = 5.0
	return light

func _find_and_dim_lights(node: Node):
	if node is Light3D:
		_stored_lights[node] = node.light_energy
		node.light_energy = 0.0
	
	for child in node.get_children():
		_find_and_dim_lights(child)

func restore_lights():
	for light in _stored_lights:
		if is_instance_valid(light):
			light.light_energy = _stored_lights[light]
	_stored_lights.clear()
