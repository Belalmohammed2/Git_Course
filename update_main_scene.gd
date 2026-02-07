extends SceneTree

func _init():
    print("Starting scene update...")
    var scene_path = "res://main.tscn"
    var scene = load(scene_path).instantiate()
    
    var spooky_light_scn = load("res://entities/environment/spooky_light/SpookyLight.tscn")
    var wall_scn = load("res://entities/environment/hallway_wall/HallwayWall.tscn")

    # 1. Replace SpookyLight
    var old_light = scene.get_node("SpookyLight")
    if old_light:
        print("Found old SpookyLight")
        var parent = old_light.get_parent()
        var xform = old_light.transform
        
        var new_light = spooky_light_scn.instantiate()
        new_light.name = "SpookyLight"
        new_light.transform = xform
        
        parent.remove_child(old_light)
        old_light.queue_free()
        
        parent.add_child(new_light)
        new_light.owner = scene
        print("Replaced SpookyLight")
    
    # 2. Replace Walls
    # HallwayLeftWall
    var hallway = scene.get_node("Hallway")
    if hallway:
        _replace_wall(hallway, "HallwayLeftWall", wall_scn, scene)
        _replace_wall(hallway, "HallwayRightWall", wall_scn, scene)
    
    # Save
    var packed = PackedScene.new()
    packed.pack(scene)
    ResourceSaver.save(packed, scene_path)
    print("Saved main.tscn")
    quit()

func _replace_wall(parent, node_name, wall_scn, scene_root):
    var old_node = parent.get_node(node_name)
    if old_node:
        print("Found ", node_name)
        var xform = old_node.transform
        
        var new_node = wall_scn.instantiate()
        new_node.name = node_name # Keep the name "HallwayLeftWall" etc. or usage "HallwayWall" ? 
        # User said "Entities must have their own subfolder". 
        # Naming the instance "HallwayLeftWall" is fine as it identifies the instance.
        new_node.transform = xform
        
        parent.remove_child(old_node)
        old_node.queue_free()
        
        parent.add_child(new_node)
        new_node.owner = scene_root
        print("Replaced ", node_name)
