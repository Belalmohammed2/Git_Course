extends Area3D

@export var door: Node3D
@export var dark_figure: Node3D
@export var sound_track: AudioStream
@export var custom_animation: Animation
@export var move_duration: float = 1.0

var _triggered: bool = false
var _audio_player: AudioStreamPlayer3D

func _ready() -> void:
	print("DarkFigureTrigger: _ready() called. Node: ", name, " at ", global_position)
	_audio_player = AudioStreamPlayer3D.new()
	add_child(_audio_player)
	
	# Ensure monitoring is on
	monitoring = true
	monitorable = true
	
	# Connect signal immediately
	body_entered.connect(_on_body_entered)
	
	# Auto-setup Collision Shape if missing
	var col_shape = find_child("CollisionShape3D", true, false)
	if col_shape:
		print("DarkFigureTrigger: CollisionShape3D found.")
		if not col_shape.shape:
			print("DarkFigureTrigger: Shape resource is MISSING. Creating default BoxShape3D.")
			var box = BoxShape3D.new()
			box.size = Vector3(1.0, 2.0, 1.0) # Fits in door
			col_shape.shape = box
		else:
			print("DarkFigureTrigger: Shape resource ALREADY EXISTS.")
	else:
		print("DarkFigureTrigger: CollisionShape3D node NOT FOUND!")
		# Force create one if missing
		var new_col = CollisionShape3D.new()
		new_col.name = "CollisionShape3D"
		var box = BoxShape3D.new()
		box.size = Vector3(3.0, 3.0, 3.0) 
		new_col.shape = box
		add_child(new_col)
		print("DarkFigureTrigger: Created new CollisionShape3D/BoxShape3D entirely.")

func _on_body_entered(body: Node3D) -> void:
	print("DarkFigureTrigger: Body entered -> ", body.name)
	if _triggered:
		return
		
	# Check for Player
	if body.is_in_group("Player") or body.name == "Player":
		print("DarkFigureTrigger: Player detected.")
		
		# Check if Door is assigned
		if door:
			 # Check if door has 'is_open' property
			if "is_open" in door:
				print("DarkFigureTrigger: Door is_open = ", door.is_open)
				if door.is_open:
					trigger_event(body)
				else:
					print("DarkFigureTrigger: Door is CLOSED. Event blocked.")
			else:
				print("DarkFigureTrigger: Door script has no 'is_open' property! Triggering anyway.")
				trigger_event(body)
		else:
			# If no door assigned, just trigger (fallback)
			print("DarkFigureTrigger: No door assigned. Triggering immediately.")
			trigger_event(body)

func trigger_event(target_player: Node3D) -> void:
	print("DarkFigureTrigger: Event Started!")
	_triggered = true
	
	# 1. Play Sound
	if sound_track:
		_audio_player.stream = sound_track
		_audio_player.play()
		
	# 2. Handle Dark Figure
	if dark_figure:
		dark_figure.visible = true
		

		# Debug Animation
		var anim_player = dark_figure.find_child("AnimationPlayer", true, false)
		if anim_player:
			# 2a. Priority: Custom Dropped Animation
			if custom_animation:
				print("DarkFigureTrigger: Playing custom dropped animation resource.")
				var lib_name = "runtime_overrides"
				var final_name = "dropped_anim"
				
				# Check if library already exists (rare re-trigger case)
				if not anim_player.has_animation_library(lib_name):
					var lib = AnimationLibrary.new()
					lib.add_animation(final_name, custom_animation)
					anim_player.add_animation_library(lib_name, lib)
				
				# Play custom animation (User requested NORMAL speed)
				var speed_scale = 1.0
				print("DarkFigureTrigger: Playing animation with speed_scale: ", speed_scale)
				anim_player.play(lib_name + "/" + final_name, -1, speed_scale)
				
			else:
				# 2b. Fallback: String matching
				var anim_list = anim_player.get_animation_library_list() # Debug print
				
				# Normal speed
				var speed_scale = 1.0
				
				# Found in tscn: "libraries/walk relaxed " -> "walk relaxed /walk relaxed"
				if anim_player.has_animation("walk relaxed"):
					anim_player.play("walk relaxed", -1, speed_scale)
				elif anim_player.has_animation("walk relaxed/walk relaxed"):
					anim_player.play("walk relaxed/walk relaxed", -1, speed_scale)
				elif anim_player.has_animation("walk relaxed /walk relaxed"):
					anim_player.play("walk relaxed /walk relaxed", -1, speed_scale)
				else:
					var all_anims = anim_player.get_animation_list()
					if all_anims.size() > 0:
						print("DarkFigureTrigger: 'walk relaxed' not found. Playing first available: ", all_anims[0])
						anim_player.play(all_anims[0], -1, speed_scale)
		else:
			print("DarkFigureTrigger: No AnimationPlayer found on Dark Figure.")
			
		# 3. Horror Light Effect
		var light = OmniLight3D.new()
		light.light_color = Color(1.0, 0.0, 0.0) # RED
		light.light_energy = 0.0
		light.omni_range = 5.0
		dark_figure.add_child(light)
		# Position light at head approx height (local Y=1.5)
		light.position.y = 1.5 
		
		# Flicker Up
		var light_tween = create_tween()
		light_tween.tween_property(light, "light_energy", 3.0, 0.1).set_trans(Tween.TRANS_BOUNCE)
		
		# 4. Move towards Player
		var tween = create_tween()
		
		var duration = move_duration
			
		print("DarkFigureTrigger: STARTING TWEEN. Duration: ", duration, " (Exported move_duration: ", move_duration, ")")
			
		tween.tween_property(dark_figure, "global_position:x", target_player.global_position.x, duration)

		
		# 5. Disappear immediately upon contact (End of tween)
		await tween.finished
		dark_figure.visible = false
		if light:
			light.queue_free()
		print("DarkFigureTrigger: Dark Figure vanished on contact.")
		
	else:
		print("DarkFigureTrigger: Dark Figure node not assigned!")
