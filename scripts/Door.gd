extends Node3D

@export var open_sound: AudioStream
@export var locked_sound: AudioStream # Sound to play when locked
@export var required_key_id: String = "" # If empty, openable by anyone
@export var animation_player: AnimationPlayer
@export var animation_name: String = "mixamo.com" 

# Animation Times
@export var open_start: float = 0.0
@export var open_end: float = 1.5
@export var close_start: float = 2.19
@export var close_end: float = 3.8
@export var locked_start: float = 3.9
@export var locked_end: float = 4.6

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var interact_label: Label3D = $Global_Control/SimpleDoor_MainDoor_LOD0/InteractLabel

var is_open: bool = false
var is_moving: bool = false 

func _ready():
	if not animation_player:
		animation_player = find_child("AnimationPlayer", true, false)
	
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)
		
	# Auto-load locked sound if not set
	if not locked_sound:
		var default_path = "res://assets/Apartment_Door/Sounds/locked door shaking .mp3"
		if ResourceLoader.exists(default_path):
			locked_sound = load(default_path)
			print("Door: Auto-loaded locked sound.")
		else:
			push_warning("Door: Default locked sound not found at: ", default_path)
		
	# Ensure label is hidden at start
	if interact_label:
		interact_label.visible = false

# Called by Player when looking at this object
func focused():
	if interact_label:
		interact_label.visible = true

# Called by Player when looking away
func unfocused():
	if interact_label:
		interact_label.visible = false

func interact():
	if is_moving: return
	
	# Key Check
	if required_key_id != "":
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			if "keys" in player and player.keys.has(required_key_id):
				print("Door: Unlocked with key ", required_key_id)
				# Proceed to open - Fall through to normal logic
			else:
				print("Door: Locked! Requires ", required_key_id)
				
				# LOCKED FEEDBACK
				if locked_sound:
					audio_player.stream = locked_sound
					audio_player.play()
				
				if player and player.has_method("update_objective"):
					print("Door: Calling update_objective")
					player.update_objective("Find the key")
				else:
					print("Door: Player or update_objective not found")
				
				is_moving = true
				if animation_player:
					var anim_list = animation_player.get_animation_list()
					if anim_list.size() > 0:
						var anim_to_play = animation_name if animation_player.has_animation(animation_name) else anim_list[0]
						animation_player.play(anim_to_play)
						
						# Play Locked Shake
						animation_player.seek(locked_start, true)
						var duration = locked_end - locked_start
						if duration > 0:
							await get_tree().create_timer(duration).timeout
							animation_player.pause()
				
				is_moving = false
				return # Stop here, don't open
	
	print("Door: Interact!", is_open)
	is_moving = true
	
	if open_sound:
		audio_player.stream = open_sound
		audio_player.play()
	
	if animation_player:
		var anim_list = animation_player.get_animation_list()
		if anim_list.size() > 0:
			var anim_to_play = animation_name if animation_player.has_animation(animation_name) else anim_list[0]
			
			animation_player.play(anim_to_play)
			
			if not is_open:
				animation_player.seek(open_start, true)
				var duration = open_end - open_start
				await get_tree().create_timer(duration).timeout
				animation_player.pause()
				is_open = true
			else:
				animation_player.seek(close_start, true)
				var duration = close_end - close_start
				await get_tree().create_timer(duration).timeout
				animation_player.pause()
				is_open = false
				
	else:
		# Fallback
		var door_mesh = find_child("*MainDoor*", true, false)
		if door_mesh:
			var tween = create_tween()
			if not is_open:
				tween.tween_property(door_mesh, "rotation_degrees:y", 90.0, 1.5)
				is_open = true
			else:
				tween.tween_property(door_mesh, "rotation_degrees:y", 0.0, 1.5)
				is_open = false
			await tween.finished
			
	is_moving = false

func force_close():
	print("Door: Force closing!")
	is_open = false
	is_moving = false
	
	if animation_player:
		animation_player.play(animation_name)
		animation_player.seek(0.0, true)
		animation_player.pause()
	else:
		var door_mesh = find_child("*MainDoor*", true, false)
		if door_mesh:
			door_mesh.rotation_degrees.y = 0.0
