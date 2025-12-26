extends CharacterBody2D

signal clone_finished(clone)

var replay_buffer = []
var replay_index = 0
var rewinding = false

@onready var animated_sprite_2d = $AnimatedSprite2D

func _ready():
	set_physics_process(true)
	animated_sprite_2d.modulate.a = 0.5

func _physics_process(delta):
	if replay_buffer.size() == 0:
		return

	if rewinding:
		replay_index -= 1
		if replay_index < 0:
			replay_index = 0
			rewinding = false

	else:
		replay_index += 1
		if replay_index >= replay_buffer.size():
			replay_index = replay_buffer.size() - 1
			rewinding = true

	var state = replay_buffer[replay_index]
	position = state["position"]
	velocity = state["velocity"]
	animated_sprite_2d.animation = state["animation"]
	animated_sprite_2d.flip_h = state["flip_h"]

	if state.has("interact") and state["interact"] and not rewinding:

		print("Flicking switch")
		state["interact"]._on_interact(self)
