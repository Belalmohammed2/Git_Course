extends Node3D

@export var key_id: String = "key_01"

@export var pickup_sound: AudioStream

func focused():
	# Optional: Show outline or label
	pass

func unfocused():
	pass

func interact():
	if not is_inside_tree(): return
	
	print("Picked up key: ", key_id)
	
	# Play Sound if assigned
	if pickup_sound:
		var audio_node = AudioStreamPlayer.new()
		audio_node.stream = pickup_sound
		audio_node.finished.connect(audio_node.queue_free)
		get_tree().root.add_child(audio_node)
		audio_node.play()
		
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("add_key"):
		player.add_key(key_id)
		queue_free() # Remove from world
