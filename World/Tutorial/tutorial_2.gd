extends Node2D

var replay_time := 0.0

@export var zone_ghost_map: Dictionary = {}

func _ready():
	# Connect signals for all zones in the mapping
	for zone_name in zone_ghost_map.keys():
		var zone = get_node_or_null(zone_name)
		if zone:
			zone.state_changed.connect(_on_zone_state_changed.bind(zone))
	
	# Hide all ghosts initially
	for ghost_paths in zone_ghost_map.values():
		for ghost_path in ghost_paths:
			var ghost = get_node_or_null(ghost_path)
			if ghost:
				ghost.visible = false

func _on_zone_state_changed(state, zone):
	var zone_name = zone.name
	if zone_ghost_map.has(zone_name):
		for ghost_path in zone_ghost_map[zone_name]:
			var ghost = get_node_or_null(ghost_path)
			if ghost:
				ghost.visible = state


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	replay_time += delta
	# Asume Branch_duration of 5 for simplicty
	# FIXME This is something I just dont want to deal with right now...
	if replay_time > 5:
		replay_time = 0
	pass
