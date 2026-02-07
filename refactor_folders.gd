extends SceneTree

func _init():
    print("Starting folder refactor...")
    
    # 1. Create Directories
    var dirs = [
        "res://entities/environment/spooky_light",
        "res://entities/environment/hallway_wall"
    ]
    
    for d in dirs:
        if not DirAccess.dir_exists_absolute(d):
            var err = DirAccess.make_dir_recursive_absolute(d)
            if err == OK:
                print("Created dir: ", d)
            else:
                print("Failed to create dir: ", d, " Error: ", err)

    # 2. Handle SpookyLight
    # Move Script
    var old_script_path = "res://SpookyLight.gd"
    var new_script_path = "res://entities/environment/spooky_light/SpookyLight.gd"
    
    var script = load(old_script_path)
    if script:
        ResourceSaver.save(script, new_script_path)
        print("Moved SpookyLight.gd")
    else:
        print("Warning: SpookyLight.gd not found at root")

    # Create SpookyLight.tscn
    var light = OmniLight3D.new()
    light.name = "SpookyLight"
    light.script = load(new_script_path) # Attach new script
    # Matches Main: unique_id=1005057596 (we don't preserve ID in the prefab class generally, but in main instance we might)
    # Default params from script will verify
    
    var packed_light = PackedScene.new()
    packed_light.pack(light)
    ResourceSaver.save(packed_light, "res://entities/environment/spooky_light/SpookyLight.tscn")
    print("Created SpookyLight.tscn")
    
    # 3. Handle HallwayWall
    # Move Assets
    var assets_to_move = {
        "res://assets/hallway_wall_mesh.tres": "res://entities/environment/hallway_wall/hallway_wall_mesh.tres",
        "res://assets/hallway_wall_shape.tres": "res://entities/environment/hallway_wall/hallway_wall_shape.tres"
    }
    
    for old_p in assets_to_move:
        var res = load(old_p)
        if res:
            ResourceSaver.save(res, assets_to_move[old_p])
            print("Copied asset to: ", assets_to_move[old_p])
        else:
            print("Error: content not found for ", old_p)

    # Create HallwayWall.tscn
    var wall_root = StaticBody3D.new()
    wall_root.name = "HallwayWall"
    
    var mesh_inst = MeshInstance3D.new()
    mesh_inst.name = "WallMesh"
    mesh_inst.mesh = load("res://entities/environment/hallway_wall/hallway_wall_mesh.tres")
    wall_root.add_child(mesh_inst)
    mesh_inst.owner = wall_root
    
    var col = CollisionShape3D.new()
    col.name = "WallCollision"
    col.shape = load("res://entities/environment/hallway_wall/hallway_wall_shape.tres")
    wall_root.add_child(col)
    col.owner = wall_root
    
    var packed_wall = PackedScene.new()
    packed_wall.pack(wall_root)
    ResourceSaver.save(packed_wall, "res://entities/environment/hallway_wall/HallwayWall.tscn")
    print("Created HallwayWall.tscn")

    quit()
