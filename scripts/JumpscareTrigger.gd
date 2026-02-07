extends Area3D

@export var door: Node3D
@export var shadow_figure: Node3D
@export var scream_sound: AudioStream
@export var move_speed: float = 20.0 # Fast!
@export var move_duration: float = 0.5

var _triggered: bool = false
var _audio_player: AudioStreamPlayer

func _ready():
	print("Jumpscare2: Trigger READY at ", global_position)
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	
	if shadow_figure:
		shadow_figure.visible = false # Hide initially

func _on_body_entered(body):
	print("Jumpscare2: Body entered: ", body.name, " Groups: ", body.get_groups())
	if _triggered: return
	
	if body.is_in_group("Player"):
		trigger_jumpscare(body)

func trigger_jumpscare(player):
	print("Jumpscare2: Triggered!")
	_triggered = true
	
	# 1. Slam Door
	if door and door.has_method("force_close"):
		door.force_close()
		# Optionally play a slam sound here if Door.gd doesn't handle "forced" sound
	
	# 2. Activate Shadow Figure
	if shadow_figure:
		shadow_figure.visible = true
		shadow_figure.global_position = global_position # Start at trigger or specific point
		
		# Look at player
		shadow_figure.look_at(player.global_position, Vector3.UP)
		
		# 3. Play Scream
		if scream_sound:
			_audio_player.stream = scream_sound
			_audio_player.play()
		
		# 4. Move to Camera & Fade
		var camera = player.get_viewport().get_camera_3d()
		var target_pos = camera.global_position if camera else player.global_position
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(shadow_figure, "global_position", target_pos, move_duration)
		
		# Try to fade out if mesh allows transparency
		# We'll try to set opacity on the mesh instance if possible
		var mesh_instance = shadow_figure.find_child("MeshInstance3D", true, false)
		if mesh_instance:
			# Ensure material is unique so we don't fade everything
			var mat = mesh_instance.get_active_material(0)
			if mat:
				mat = mat.duplicate()
				mesh_instance.material_override = mat
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				tween.tween_property(mat, "albedo_color:a", 0.0, move_duration)
		
		await tween.finished
		shadow_figure.visible = false
		queue_free() # Remove trigger logic
