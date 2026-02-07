# Project Rules

## SCALE & UNITS
- **1.0 unit = 1.0 meter.**
- My player is exactly **1.8 units tall**.
- Before creating or moving any 3D node, always check the surrounding scene scale.
- **Never set a Node's scale property to anything other than (1, 1, 1)** unless explicitly asked.
- Use the `mesh.size` property to change dimensions instead.

## MESH ASSIGNMENT
- Every `MeshInstance3D` you create **MUST** have an assigned Mesh resource (e.g., `BoxMesh.new()`, `PlaneMesh.new()`).
- Never leave the mesh property null.

## SCENE TREE HYGIENE
- Always parent new nodes to the designated 'Root' or 'World' node.
- After adding a node, use the `save_scene` tool immediately to ensure Godot 4.6 reflects the change.

## SYNTAX
- Use **Godot 4.6 GDScript syntax**.
- Use `@export` for variables.
- Ensure all node references use the **unique_name_in_owner (%)** system where appropriate for horror triggers.

## BLENDER WORKFLOW
- Assume all `.blend` imports are at a **1:1 scale**.
- If a model looks "huge," **do not scale it down**; instead, check if the parent transform needs resetting to `(1, 1, 1)`.
