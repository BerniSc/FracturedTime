extends CharacterBody2D

const SPEED = 110.0
const JUMP_VELOCITY = -350
const REWIND_DURATION_SECS = 2.0
const BRANCH_RECORD_DURATION_SECS = 2.0

signal branch_finished(branch_player, buffer, end_position)

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

## Glide
@export var enable_glide := true
# Slow down gravity -> less means slower fall
@export var glide_gravity_scale := 0.2

var is_gliding := false

## Walljmp/Glide
@export var enable_wall_jump := true
@export var enable_wall_slide := true
@export var wall_slide_speed := 40.0
 # X is horizontal push, Y is upward
@export var wall_jump_velocity := Vector2(100, -250)

# Prevent endless climbing (and ensure momentum of jmp does not get overwritten by user input)
@export var wall_jump_lock_time_sec := 0.8
@export var wall_jump_input_lock_time_sec := 0.15
var wall_jump_lock_timer := 0.0
var wall_jump_input_lock_timer := 0.0

var is_wall_sliding := false
var wall_dir := 0 # -1 for left, 1 for right

# /EXPERIMENTAL
# ==================================

func _physics_process(delta):
	if is_frozen:
		return
	
	if is_rewinding:
		rewind_step()
		return

	# Update lock-timers
	if wall_jump_lock_timer > 0.0:
		wall_jump_lock_timer -= delta
	if wall_jump_input_lock_timer > 0.0:
		wall_jump_input_lock_timer -= delta

	# Record current state
	record_state()

	# Wall slide logic
	is_wall_sliding = false
	wall_dir = 0
	if enable_wall_slide and not is_on_floor() and is_on_wall() and wall_jump_lock_timer <= 0.0:
		wall_dir = get_wall_direction()
		if velocity.y > 0:
			is_wall_sliding = true
			velocity.y = min(velocity.y, wall_slide_speed)


	# Add gravity or glide
	if not is_on_floor():
		if enable_glide and Input.is_action_pressed("ui_accept") and velocity.y > 0:
			is_gliding = true
			velocity.y += gravity * glide_gravity_scale * delta
		else:
			is_gliding = false
			velocity.y += gravity * delta
	else:
		is_gliding = false


	# Reset jump count when on floor
	if is_on_floor():
		jmp_cnt = 0

	# Handle Jump and doublejmp (if configured)
	# And also walljmp (if configured)
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jmp_cnt = 1
		elif enable_double_jmps and jmp_cnt < max_jmps and not is_wall_sliding:
			velocity.y = JUMP_VELOCITY * 0.75;
			jmp_cnt += 1
		elif enable_wall_jump and is_wall_sliding:
			velocity.y = wall_jump_velocity.y
			# away from wall -> Dir can flip
			velocity.x = wall_jump_velocity.x * -wall_dir
			is_wall_sliding = false
			jmp_cnt = 1 # Reset jumpcount after walljump
			# Prevent Wallslide for a moment
			wall_jump_lock_timer = wall_jump_lock_time_sec
			# Prevent input override
			wall_jump_input_lock_timer = wall_jump_input_lock_time_sec

	# Get the input direction (input_axis) and handle the movement/deceleration.
	var input_axis = Input.get_axis("ui_left", "ui_right")
	if wall_jump_input_lock_timer > 0.0:
		# Ignore horizontal input after wall jump
		pass
	elif input_axis:
		velocity.x = input_axis * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	update_animations(input_axis)

	# Dont allow rewind or branch on clone for now
	if is_branching:
		branch_timer += delta
		record_branch_state()
		if branch_timer >= BRANCH_RECORD_DURATION_SECS:
			is_branching = false
			emit_signal("branch_finished", self, branch_buffer, position)
			queue_free()
		return

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

func start_branch():
	is_frozen = true
	animated_sprite_2d.modulate.a = 0.3 # Fade out
	set_physics_process(false)
	
	# Spawn branch player
	var player_scene = preload("res://Player/player.tscn")
	var branch_player = player_scene.instantiate()
	branch_player.position = position
	branch_player.set_as_branch_player()
	get_parent().add_child(branch_player)
	branch_player.connect("branch_finished", Callable(self, "_on_branch_finished"))

func set_as_branch_player():
	# Called when this instance is used as a branch player
	self.is_branching = true
	self.branch_timer = 0.0
	self.branch_buffer = []
	self.connect("branch_finished", Callable(self, "_on_branch_finished"))
	set_physics_process(true)

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
	# Fade in
	# TODO and move to new position?
	# position = end_position
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

func get_wall_direction() -> int:
	# Returns -1 if touching left wall, 1 if right wall, 0 otherwise
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision and collision.get_normal().x > 0.9:
			return -1 # Wall on left
		elif collision and collision.get_normal().x < -0.9:
			return 1 # Wall on right
	return 0

func update_animations(input_axis):
	var coolcounter := 0
	if is_wall_sliding:
		# TODO Stub, should have implemented this
		coolcounter += 1
	elif is_gliding:
		# TODO Stub, should have implemented this
		coolcounter += 1
	if input_axis != 0:
		animated_sprite_2d.flip_h = input_axis < 0
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")

	# TODO and is not gliding and is not sliding
	if not is_on_floor():
		animated_sprite_2d.play("jump")
