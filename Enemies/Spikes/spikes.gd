extends Area2D

# How far spikes extend in pixels
@export var extend_distance: float = 64.0

# TODO IMPLEMENT
@export var extend_speed: float = 200.0

@export var start_extended := false

@export var is_top: bool = false

@export var rewind_death: bool = true

# Store original position
var base_position: Vector2
@onready var sprite: Sprite2D = $Sprite2D
@onready var shader = sprite.material as ShaderMaterial
@onready var sprite_height = sprite.texture.get_height()

signal touched_spike(body)

@onready var auto_extend_timer: Timer = $AutoExtendTimer
@onready var auto_retract_timer: Timer = $AutoRetractTimer

@export_group("Autoextend")
@export var auto_extend := false
@export var duration_extended: float = 3.0
@export var duration_retracted: float = 2.0

var cur_state_extended = false

func _ready():
	add_to_group("spikes")
	base_position = position
	body_entered.connect(_on_body_entered)
	# Create unique material for this spike instance, otherwise they share uniforms
	# Then everything sucks
	if sprite.material:
		sprite.material = sprite.material.duplicate()
		shader = sprite.material as ShaderMaterial
	reset_spikes()
	
	auto_extend_timer.wait_time = duration_extended
	auto_extend_timer.one_shot = true
	auto_extend_timer.timeout.connect(_on_auto_extend_timer_timeout)
	
	auto_retract_timer.wait_time = duration_retracted
	auto_retract_timer.one_shot = true
	auto_retract_timer.timeout.connect(_on_auto_retract_timer_timeout)
	
	if auto_extend:
		if start_extended:
			extend()
			auto_extend_timer.start()
		else:
			retract()
			auto_retract_timer.start()
	else:
		auto_extend_timer.stop()
		auto_retract_timer.stop()


func _on_auto_extend_timer_timeout():
	retract()
	auto_retract_timer.start()

func _on_auto_retract_timer_timeout():
	extend()
	auto_extend_timer.start()

func _on_body_entered(body):
	# Only player connected, no need to check if touched body is player
	# TODO good style this way? Rethink!
	if body.is_in_group("player"):
		emit_signal("touched_spike", self)

func reset_spikes():
	scale.y = 1.0
	position = base_position
	if start_extended:
		extend()
	else:
		retract()

func extend():
	scale.y = 1.0 + (extend_distance / sprite_height)
	position.y = base_position.y - sprite_height * (scale.y - 1.5) * (-1 if is_top else 1)
	shader.set_shader_parameter("extension", extend_distance)
	cur_state_extended = true

func retract():
	scale.y = 1.0
	position.y = 0
	position = base_position
	shader.set_shader_parameter("extension", 0.0)
	cur_state_extended = false

func _on_change_spikestate(new_state):
	# Invert logic if start_extended is true
	var extended = new_state == 1.0
	if start_extended:
		extended = not extended

	if extended:
		extend()
	else:
		retract()


func _on_switch_state_changed(new_state: Variant) -> void:
	pass # Replace with function body.
