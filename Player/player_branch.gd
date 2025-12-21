extends CharacterBody2D

signal branch_finished(branch_player, buffer, end_position)

var record_duration = 2.0
var timer = 0.0
var buffer = []

@onready var animated_sprite_2d = $AnimatedSprite2D

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	timer += delta
	record_state()
	handle_input(delta)
	if timer >= record_duration:
		emit_signal("branch_finished", self, buffer, position)
		queue_free()

func record_state():
	var state = {
		"position": position,
		"velocity": velocity,
		"animation": animated_sprite_2d.animation,
		"flip_h": animated_sprite_2d.flip_h
	}
	buffer.push_back(state)

func handle_input(delta):
	# Copy your movement/jump logic from player.gd here
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -400 # Or use your JUMP_VELOCITY

	var input_axis = Input.get_axis("ui_left", "ui_right")
	if input_axis:
		velocity.x = input_axis * 110.0 # Or use your SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, 110.0)

	move_and_slide()
	update_animations(input_axis)

func update_animations(input_axis):
	if input_axis != 0:
		animated_sprite_2d.flip_h = input_axis < 0
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
	if not is_on_floor():
		animated_sprite_2d.play("jump")
