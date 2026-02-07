GODOT 4.6 HORROR MASTER RULES
THE 4x3 LAW: The universal scale for this project is based on the 'main' wall, which is exactly 4 meters wide and 3 meters tall.

HUMAN REFERENCE: Assume the player is 1.8 units (meters) tall.

NODE HYGIENE: Every MeshInstance3D created MUST be assigned a Mesh resource (e.g., BoxMesh.new()) immediately.

THE SCALE RULE: Never modify the scale property of a Node3D; keep it at (1, 1, 1). Change dimensions using the mesh.size property instead.


FOR ALL FUTURE CREATIONS:

You MUST use this exact GDScript pattern for Godot 4.6:

```gdscript
var wall = MeshInstance3D.new()
wall.mesh = BoxMesh.new() # Assign the resource!
wall.mesh.size = Vector3(4, 3, 0.1)
add_child(wall)
wall.owner = get_tree().edited_scene_root # Crucial for Editor visibility
```
