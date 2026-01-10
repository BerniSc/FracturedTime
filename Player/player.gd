extends CharacterBody2D

const SPEED = 110.0
const JUMP_VELOCITY = -350
const REWIND_DURATION_SECS = 2.0
const BRANCH_RECORD_DURATION_SECS = 2.0

signal branch_began(slot_index)
signal branch_finished(branch_player, buffer, end_position, slot_index)

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var hud = find_hud()
@onready var iframe_timer: Timer = $IFrameTimer

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var state_buffer = []
var buffer_max_frames = int(REWIND_DURATION_SECS * Engine.get_physics_ticks_per_second())
var is_rewinding = false
var died_rewind := false

var is_branching = false
var branch_timer = 0.0
var branch_buffer = []

var is_frozen = false
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
@export var glide_gravity_scale := 0.1

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
var last_wall_dir := 0

# /EXPERIMENTAL
# ==================================

# Record interactables so we can replay their actions
var current_interactable: BaseInteractable = null

func set_current_interactable(interactable):
	current_interactable = interactable

func clear_current_interactable(interactable):
	if current_interactable == interactable:
		current_interactable = null

var can_die := false

func _ready():
	add_to_group("player")
	active_clones.resize(GameSettings.MAX_CLONES)
	call_deferred("_connect_spike_signals")
	call_deferred("_connect_boulder_signals")
	call_deferred("_connect_hud_signals")
	iframe_timer.timeout.connect(func(): can_die = true)
	
func _exit_tree():
	# Reset respawn position when scene is exited
	GameState.checkpoint_position = null

func _connect_spike_signals():
	for spike in get_tree().get_nodes_in_group("spikes"):
		spike.connect("touched_spike", func(spike): _on_die(spike))
	print("Connected spikes:", get_tree().get_nodes_in_group("spikes"))

func _connect_boulder_signals():
	for boulder in get_tree().get_nodes_in_group("boulder"):
		boulder.connect("touched_boulder", func(bldr): if bldr.will_kill(): _on_die(bldr))
	print("Connected boulders:", get_tree().get_nodes_in_group("boulder"))

func _connect_hud_signals():
	connect("branch_began", Callable(hud, "_on_branch_began"))
	connect("branch_finished", Callable(hud, "_on_branch_finished"))

func _on_die(killer):
	if !can_die:
		return
	print("DIED")
	if ("rewind_death" in killer) and killer.rewind_death:
		died_rewind = true
	else:
		if(GameState.checkpoint_position != null):
			global_position = GameState.checkpoint_position
		else:
			get_tree().reload_current_scene()

func _physics_process(delta):
	if is_frozen:
		return
	
	if is_rewinding or died_rewind:
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
	wall_dir = get_wall_direction()
	if enable_wall_slide and not is_on_floor() and is_on_wall():
		is_wall_sliding = true
		if velocity.y > 0:
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
			last_wall_dir = 0
			$JumpSound.play()
		elif enable_double_jmps and jmp_cnt < max_jmps and not is_wall_sliding:
			velocity.y = JUMP_VELOCITY * 0.75;
			jmp_cnt += 1
			$JumpSound.play()
		elif enable_wall_jump and is_wall_sliding and wall_dir != 0:
			if wall_dir != last_wall_dir or wall_jump_lock_timer <= 0.0:
				velocity.y = wall_jump_velocity.y
				# away from wall -> Dir can flip
				velocity.x = wall_jump_velocity.x * -wall_dir
				# Prevent onesided Wallclimbs
				last_wall_dir = wall_dir
				is_wall_sliding = false
				#jmp_cnt = 1 # Reset jumpcount after walljump
				# Prevent OneSided Walljumps for a moment
				wall_jump_lock_timer = wall_jump_lock_time_sec
				# Prevent input override
				wall_jump_input_lock_timer = wall_jump_input_lock_time_sec
				$JumpSound.play()
			else:
				pass

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

	# Interactions get handled by interactables and signals are thrown

	# if we do not yet have "time" unlocked exit early here to prevent it
	if !GameState.branch_allowed:
		return

	# Dont allow rewind or branch on clone for now
	if is_branching:
		branch_timer += delta
		record_branch_state()
		if Input.is_action_just_pressed("ui_interact"):
			branch_buffer.back().interact = current_interactable
		if branch_timer >= BRANCH_RECORD_DURATION_SECS:
			is_branching = false
			emit_signal("branch_finished", self, branch_buffer, position, hud.selected_slot)
			queue_free()
		return

	# Check for Zoom-Out Request
	if Input.is_action_pressed("zoom") and GameState.can_zoom:
		$Camera2D.zoom = Vector2(0.65, 0.65)
	else:
		$Camera2D.zoom = Vector2(1, 1)

	# Check for rewind shortcut
	if Input.is_action_just_pressed("rewind"):
		is_rewinding = true
	
	# Branch shortcut (spawn clone)
	var clone_count = active_clones.count(func(c): return c != null)
	if Input.is_action_just_pressed("branch") and clone_count  < GameSettings.MAX_CLONES:
		start_branch()

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
	ghost.call_deferred("setup", texture, region, state["flip_h"], sprite_offset)

func record_state():
	var state = {
		"position": position,
		"velocity": velocity,
		"animation": animated_sprite_2d.animation,
		"flip_h": animated_sprite_2d.flip_h,
		"interact": null  # will be set if interaction happened in frame
	}
	state_buffer.push_front(state)
	if state_buffer.size() > buffer_max_frames:
		state_buffer.pop_back()

func rewind_step():
	if state_buffer.size() == 0 or (not Input.is_action_pressed("rewind") and not died_rewind):
		is_rewinding = false
		died_rewind = false
		return

	print("POPPING")
	var state = state_buffer.pop_front()
	spawn_ghost_from_state(state)
	position = state["position"]
	velocity = state["velocity"]
	animated_sprite_2d.animation = state["animation"]
	animated_sprite_2d.flip_h = state["flip_h"]

func start_branch():
	is_frozen = true
	animated_sprite_2d.modulate.a = 0.3 # Fade out
	set_physics_process(false)
	
	emit_signal("branch_began", hud.selected_slot)
	
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
	set_physics_process(true)

func record_branch_state():
	var state = {
		"position": position,
		"velocity": velocity,
		"animation": animated_sprite_2d.animation,
		"flip_h": animated_sprite_2d.flip_h,
		"interact": null  # will be set if interaction happened in frame
	}
	branch_buffer.push_back(state)


func end_branch():
	is_branching = false
	animated_sprite_2d.modulate.a = 1.0 # Fade in
	branch_buffer.clear()

func spawn_branch_clone(buffer):
	var slot = hud.selected_slot
	
	# Remove existing clone in this slot if it exists
	if active_clones[slot]:
		active_clones[slot].queue_free()
		active_clones[slot] = null

	# Create and add new clone
	var clone_scene = preload("res://Player/player_clone.tscn")
	var clone = clone_scene.instantiate()
	clone.position = buffer[0]["position"]
	clone.replay_buffer = buffer
	clone.slot_idx = slot
	get_parent().add_child(clone)
	active_clones[slot] = clone
	
	clone.connect("clone_finished", Callable(self, "_on_clone_done"))
	# hud.set_slot_occupied(slot, true)
	
func _on_branch_finished(branch_player, buffer, end_position, selected_slot_idx):
	# Fade in
	# TODO and move to new position?
	# position = end_position
	animated_sprite_2d.modulate.a = 1.0
	set_physics_process(true)
	is_frozen = false
	spawn_branch_clone(buffer)

# TODO @Deprecation?
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

func find_hud():
	var root = get_tree().get_root()
	for child in root.get_children():
		if child.has_node("HUD"):
			return child.get_node("HUD")
	return null

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
