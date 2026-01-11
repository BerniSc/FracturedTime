# Autoload-Singelton -> Stores gamestate
extends Node

var branch_allowed = false
var can_zoom := false

var is_debug := false

var checkpoint_position = null

# Set this in a door once we "leave" to it. If it was one we can try restoring the position
# Otherwise not. This is needed not to have the clone spawn on the respawnpoint
var was_door_transition := false

# Map: scene_name (or unique node name) -> Vector2 position
var last_positions := {}

# The last scene's unique name
var last_scene_name := ""

# Set before changing scene
func set_next_spawn(scene_name: String, position: Vector2):
	print("Last pos; ", last_positions)
	print("LastSceneName: ", last_scene_name)
	last_positions[scene_name] = position
	last_scene_name = scene_name

# Get position for current scene, if any
func get_spawn_for_scene(scene_name: String) -> Variant:
	print("last_scene_name ", last_scene_name, " sc ", scene_name)
	if last_positions.has(scene_name):
		return last_positions[scene_name]
	return null
