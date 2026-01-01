extends Area2D

# How far spikes extend in pixels
@export var extend_distance: float = 64.0

# TODO IMPLEMENT
@export var extend_speed: float = 200.0

@export var start_extended := false

# Store original position
var base_position: Vector2
@onready var sprite: Sprite2D = $Sprite2D
@onready var shader = sprite.material as ShaderMaterial
@onready var sprite_height = sprite.texture.get_height()

signal touched_spike(body)

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

func _on_body_entered(body):
	emit_signal("touched_spike", body)

func reset_spikes():
	scale.y = 1.0
	position = base_position
	if start_extended:
		extend()
	else:
		retract()

func extend():
	scale.y = 1.0 + (extend_distance / sprite_height)
	position.y = base_position.y - sprite_height * (scale.y - 1.5)
	shader.set_shader_parameter("extension", extend_distance)

func retract():
	scale.y = 1.0
	position.y = 0
	position = base_position
	shader.set_shader_parameter("extension", 0.0)

func _on_change_spikestate(new_state):
	# Invert logic if start_extended is true
	var extended = new_state == 1.0
	if start_extended:
		extended = not extended

	if extended:
		extend()
	else:
		retract()
