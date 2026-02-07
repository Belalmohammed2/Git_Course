extends CharacterBody3D

@export var speed: float = 0.2
@export var gravity_scale: float = 1.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Force the animation to loop
	var anim_player = $Model/AnimationPlayer
	if anim_player:
		var anim_name = anim_player.autoplay
		if anim_name:
			var anim = anim_player.get_animation(anim_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
				anim_player.play(anim_name) # Restart to ensure loop takes effect

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * gravity_scale * delta

	# Move forward along the object's local Z axis
	# transform.basis.z is the forward vector in local space (usually backwards in Godot, so -basis.z is forward)
	# However, for CharacterBody3D, we usually want to move in the direction the character is facing.
	
	# Assuming the model faces -Z (Godot standard). 
	var direction = -transform.basis.z
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
