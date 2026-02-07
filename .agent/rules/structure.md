# Folder Structure Rules

To keep the project modular and scalable, we strictly follow this folder architecture:

1.  **Entity-Component Structure**:
    *   Every entity (e.g., Player, Door, Flashlight, Monster) MUST have its own dedicated subfolder inside `res://entities/` (for gameplay entities) or `res://props/` (for static objects).
    *   The folder name should match the entity name (snake_case is preferred for folders, PascalCase for scene files).

2.  **Co-location Rule**:
    *   The `.tscn` (scene), `.gd` (script), and any unique assets (models, specific textures, materials) for that entity MUST live together in its dedicated folder.
    *   Example:
        ```text
        res://entities/door/
        ├── Door.tscn
        ├── Door.gd
        ├── door_handle.glb
        └── door_wood.tres
        ```

3.  **Generic Assets**:
    *   Assets that are shared across multiple entities or are general world geometry (like generic floor tiles, shared noise textures) go in `res://assets/`.
    *   Example: `res://assets/textures/`, `res://assets/materials/`.

4.  **Script Naming**:
    *   Scripts attached to a scene's root node MUST be named exactly like the scene file.
    *   Example: `Player.tscn` -> `Player.gd`.

5.  **Scene Root**:
    *   Use `Access as Scene Name` logic where possible to avoid hard dependencies on paths.
