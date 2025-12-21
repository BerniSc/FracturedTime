extends CharacterBody2D

const SPEED = 110.0
const JUMP_VELOCITY = -400
const REWIND_DURATION_SECS = 2.0
const BRANCH_RECORD_DURATION_SECS = 2.0

@onready var animated_sprite_2d = $AnimatedSprite2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var state_buffer = []
var buffer_max_frames = int(REWIND_DURATION_SECS * Engine.get_physics_ticks_per_second())
var is_rewinding = false

var is_branching = false
var branch_timer = 0.0
var branch_buffer = []

var is_frozen = false
const MAX_CLONES = 5
var active_clones = []

# ==================================
# EXPERIMENTAL
# This is for configuring platforming (also via Inspector)
# prototyping which movements we allow. More is more fun, but harder to work around^^

## Double Jump
# use typed asignments instead of loose non-enforcing assignment
# TODO refactor rest to use theese as well
@export var enable_double_jmps := true
@export var max_jmps := 2

var jmp_cnt := 0

# /EXPERIMENTAL
# ==================================

func _physics_process(delta):
	if is_frozen:
		return
	
	if is_rewinding:
		rewind_step()
		return

	# Record current state
	record_state()

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Reset jump count when on floor
	if is_on_floor():
		jmp_cnt = 0


	# Handle Jump and doublejmp (if configured)
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jmp_cnt = 1
		elif enable_double_jmps and jmp_cnt < max_jmps:
			velocity.y = JUMP_VELOCITY * 0.75;
			jmp_cnt += 1

	# Get the input direction (input_axis) and handle the movement/deceleration.
	var input_axis = Input.get_axis("ui_left", "ui_right")
	if input_axis:
		velocity.x = input_axis * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animations(input_axis)

	# Check for rewind shortcut
	if Input.is_action_just_pressed("rewind"):
		is_rewinding = true
	
	# Branch shortcut (spawn clone)
	if Input.is_action_just_pressed("branch") and active_clones.size() < MAX_CLONES:
		start_branch()

func record_state():
	var state = {
		"position": position,
		"velocity": velocity,
		"animation": animated_sprite_2d.animation,
		"flip_h": animated_sprite_2d.flip_h
	}
	state_buffer.push_front(state)
	if state_buffer.size() > buffer_max_frames:
		state_buffer.pop_back()

func rewind_step():
	if state_buffer.size() == 0 or not Input.is_action_pressed("rewind"):
		is_rewinding = false
		return

	var state = state_buffer.pop_front()
	position = state["position"]
	velocity = state["velocity"]
	animated_sprite_2d.animation = state["animation"]
	animated_sprite_2d.flip_h = state["flip_h"]


func update_animations(input_axis):
	if input_axis != 0:
		animated_sprite_2d.flip_h = input_axis < 0
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
		
	if not is_on_floor():
		animated_sprite_2d.play("jump")

func start_branch():
	is_frozen = true
	animated_sprite_2d.modulate.a = 0.3 # Fade out
	set_physics_process(false)
	
	# Spawn branch player
	var branch_scene = preload("res://Player/player_branch.tscn")
	var branch_player = branch_scene.instantiate()
	branch_player.position = position
	branch_player.record_duration = BRANCH_RECORD_DURATION_SECS
	get_parent().add_child(branch_player)
	branch_player.connect("branch_finished", Callable(self, "_on_branch_finished"))

func record_branch_state():
	var state = {
		"position": position,
		"velocity": velocity,
		"animation": animated_sprite_2d.animation,
		"flip_h": animated_sprite_2d.flip_h
	}
	branch_buffer.push_back(state)

func end_branch():
	is_branching = false
	animated_sprite_2d.modulate.a = 1.0 # Fade in
	spawn_branch_clone(branch_buffer.duplicate())

func spawn_branch_clone(buffer):
	var clone_scene = preload("res://Player/player_clone.tscn")
	var clone = clone_scene.instantiate()
	clone.position = buffer[0]["position"]
	clone.replay_buffer = buffer
	get_parent().add_child(clone)
	active_clones.append(clone)
	clone.connect("clone_finished", Callable(self, "_on_clone_done"))
	
func _on_branch_finished(branch_player, buffer, end_position):
	# Fade in and move to new position
	position = end_position
	animated_sprite_2d.modulate.a = 1.0
	set_physics_process(true)
	is_frozen = false
	spawn_branch_clone(buffer)

func branch_clone():
	# Fade out and freeze player
	animated_sprite_2d.modulate.a = 0.3	 # Alpha = 0.3
	set_physics_process(false)
	
	# Instance and setup clone
	var clone_scene = preload("res://Player/player_clone.tscn")
	var clone = clone_scene.instantiate()
	clone.position = position
	clone.replay_buffer = state_buffer.duplicate()
	# Instantiate the clone in our worldscene or at least same scene where player lives too
	get_parent().add_child(clone)
	active_clones.append(clone)
	
	# Connect signal to restore when done
	clone.connect("clone_finished", Callable(self, "_on_clone_done"))

func _on_clone_done(clone):
	active_clones.erase(clone)
	if active_clones.size() == 0:
		# Restore player
		animated_sprite_2d.modulate.a = 1.0
		set_physics_process(true)
