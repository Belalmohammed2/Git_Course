extends Node3D

@export var player: CharacterBody3D
@export var bed_body: StaticBody3D
@export var intro_duration: float = 6.0
@export var enable_intro: bool = true
@export var breathe_sound: AudioStream

var _audio_player: AudioStreamPlayer

@onready var eyelids_layer: CanvasLayer = $EyelidsLayer
@onready var top_lid: ColorRect = $EyelidsLayer/TopLid
@onready var bottom_lid: ColorRect = $EyelidsLayer/BottomLid
@onready var ceiling_target: Node3D = $CeilingTarget

func _ready() -> void:
	# Wait for everything to settle
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	
	if not enable_intro:
		print("Intro: Disabled by Inspector setting.")
		if eyelids_layer: eyelids_layer.visible = false
		if bed_body: bed_body.process_mode = Node.PROCESS_MODE_INHERIT
		queue_free()
		return
	
	# Verify Scene
	var current_scene = get_tree().current_scene
	print("Intro: Current scene is ", current_scene.name)
	# if current_scene.name != "Level 1":
	# 	print("Intro: Skipping sequence (Not Level 1).")
	# 	if eyelids_layer: eyelids_layer.visible = false
	# 	if bed_body: bed_body.process_mode = Node.PROCESS_MODE_INHERIT
	# 	queue_free() # Remove intro logic
	# 	return
	
	# Debug
	print("Intro: Ready started.")
	
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		if not player:
			print("Intro: Player group not found! Trying to find searching children...")
			player = get_parent().find_child("Player", true, false)
	
	if player:
		print("Intro: Player found: ", player.name)
		
		# Proximity Check (Is Player on the bed?)
		var dist = global_position.distance_to(player.global_position)
		if bed_body:
			dist = bed_body.global_position.distance_to(player.global_position)
			
		print("Intro: Distance to player: ", dist)
		
		if dist < 3.0: # If on or near bed
			start_intro()
		else:
			print("Intro: Player too far (", dist, "m). Skipping.")
			if eyelids_layer: eyelids_layer.visible = false
			if bed_body: bed_body.process_mode = Node.PROCESS_MODE_INHERIT
			queue_free()
	else:
		push_error("Intro: Use 'Player' group or assign Player in Inspector! Intro aborted.")
		if eyelids_layer:
			eyelids_layer.visible = false

func start_intro() -> void:
	print("Intro: Wake up sequence started.")
	
	if breathe_sound:
		print("Intro: Playing breathe sound: ", breathe_sound.resource_path)
		_audio_player.stream = breathe_sound
		_audio_player.play()
	else:
		print("Intro: breathe_sound is NULL!")
	
	# 1. Disable Bed Collision initially
	if bed_body:
		bed_body.process_mode = Node.PROCESS_MODE_DISABLED
		bed_body.visible = true # Visible but no physics yet
	
	# 2. Lock Player & Set Initial Position (Lying Down)
	if player:
		print("Intro: Player found: ", player.name)
		var script = player.get_script()
		if script:
			print("Intro: Player script: ", script.resource_path)
			print("Intro: Has input_locked? ", "input_locked" in player)
		else:
			print("Intro: Player has NO SCRIPT attached!")
			
		# Lock Input but DO NOT MOVE PLAYER
		if "input_locked" in player:
			player.input_locked = true 
		else:
			printerr("Intro: Player missing 'input_locked' property! check Player.gd") 
		player.velocity = Vector3.ZERO
		
		# Move Head Down (Lying) & Rotate Up
		var head_node = null
		if "head" in player:
			head_node = player.head
		
		# Fallback if property missing or null
		if not head_node:
			head_node = player.find_child("Head", true, false)
			
		if head_node:
			# Default Head Y is 0.0 (Feet). Camera is 1.2.
			# Moving Head to -1.0 puts Camera at 0.2 (low)
			head_node.position.y = -1.0 
			head_node.rotation_degrees.x = -90 
		else:
			printerr("Intro: 'Head' node not found on Player!") 
		
		# Force mouse capture to ensure no unwanted movement
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	# 3. Start Black Screen (Closed Eyes)
	if top_lid: top_lid.anchor_bottom = 1.0
	if bottom_lid: bottom_lid.anchor_top = 0.0
	
	# 4. Wait 5 Seconds (Locked, Black Screen)
	await get_tree().create_timer(5.0).timeout
	
	# 5. Eye Opening Animation
	var tween = create_tween()
	
	# Open slightly -> Close -> Open Wide
	tween.tween_property(top_lid, "anchor_bottom", 0.4, 1.5).from(1.0)
	tween.parallel().tween_property(bottom_lid, "anchor_top", 0.6, 1.5).from(0.0)
	
	tween.tween_property(top_lid, "anchor_bottom", 1.0, 0.5) # Blink close
	tween.parallel().tween_property(bottom_lid, "anchor_top", 0.0, 0.5)
	
	tween.tween_property(top_lid, "anchor_bottom", 0.0, 2.0) # Open Wide
	tween.parallel().tween_property(bottom_lid, "anchor_top", 1.0, 2.0)
	
	await tween.finished
	
	# 6. Camera Look Around / Stand Up
	var stand_tween = create_tween().set_parallel(true)
	
	# Move Head UP (Stand up) - From -1.0 back to 0.0
	if player:
		var head_node = null
		if "head" in player:
			head_node = player.head
		if not head_node:
			head_node = player.find_child("Head", true, false)
			
		if head_node:
			stand_tween.tween_property(head_node, "position:y", 0.0, 3.0).set_trans(Tween.TRANS_SINE)
			
			# Rotate Head (Sit up) - From looking UP (-90) to Forward (0)
			stand_tween.tween_property(head_node, "rotation:x", 0.0, 2.5).set_trans(Tween.TRANS_SINE)
		else:
			printerr("Intro: Cannot tween Head (node missing)")
	
	await stand_tween.finished
	
	# 7. Unlock Control
	if player:
		if "input_locked" in player:
			player.input_locked = false # Unlock Input
		
		# Reset other properties if they exist
		if "locked_target" in player:
			player.locked_target = null 
			
		if player.has_method("unlock_camera"):
			player.unlock_camera() 
			
		if "dizziness" in player:
			player.dizziness = 0.5 # A bit groggy
	
	# 8. Enable Bed Collision
	if bed_body:
		bed_body.process_mode = Node.PROCESS_MODE_INHERIT
		print("Intro: Bed collision enabled.")
