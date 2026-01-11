extends CharacterBody2D

signal clone_finished(clone)

@export var replay_file: String = ""
@export var do_display_replay := true
@export var invert := false

var replay_buffer = []
var replay_index = 0
var rewinding = false

# TODO Use
var slot_idx

@onready var animated_sprite_2d = $AnimatedSprite2D

func _ready():
	if replay_file != "":
		load_demo(replay_file)
	set_physics_process(true)
	animated_sprite_2d.modulate.a = 0.5

	if invert:
		replay_index = replay_buffer.size() - 1

func load_demo(filename: String):
	var file = FileAccess.open(filename, FileAccess.READ)
	replay_buffer = file.get_var()
	file.close()
	replay_index = 0

func spawn_ghost_from_state(state):
	var ghost_scene = preload("res://Player/player_ghost.tscn")
	var ghost = ghost_scene.instantiate()
	ghost.position = state["position"]
	get_parent().add_child(ghost)

	var anim = animated_sprite_2d.animation
	var frame = animated_sprite_2d.frame
	var sprite_frames = animated_sprite_2d.sprite_frames
	var atlas_tex = sprite_frames.get_frame_texture(anim, frame)
	var region = Rect2()
	var texture = null

	if atlas_tex is AtlasTexture:
		texture = atlas_tex.atlas
		region = atlas_tex.region
	else:
		texture = atlas_tex
		region = Rect2(Vector2.ZERO, texture.get_size())

	var sprite_offset = animated_sprite_2d.position
	ghost.call_deferred("setup", texture, region, state["flip_h"], sprite_offset, 0.1)

func _physics_process(delta):
	if replay_buffer.size() == 0:
		return

	if rewinding:
		replay_index -= 1
		if replay_index < 0:
			replay_index = 0
			rewinding = false

	else:
		if !do_display_replay:
			rewinding = true
			replay_index = replay_buffer.size()
			return
		replay_index += 1
		if replay_index >= replay_buffer.size():
			replay_index = replay_buffer.size() - 1
			rewinding = true

	var state = replay_buffer[replay_index]
	position = state["position"]
	velocity = state["velocity"]
	animated_sprite_2d.animation = state["animation"]
	animated_sprite_2d.flip_h = state["flip_h"]

	if rewinding and do_display_replay:
		spawn_ghost_from_state(state)

	if state.has("interact") and state["interact"] and not rewinding:
		print("Flicking switch")
		state["interact"]._on_interact(self)
