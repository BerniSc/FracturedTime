extends Area2D

# How far spikes extend in pixels
@export var extend_distance: float = 64.0

# TODO IMPLEMENT
@export var extend_speed: float = 200.0

# Store original position
var base_position: Vector2
@onready var sprite: Sprite2D = $Sprite2D
@onready var shader = sprite.material as ShaderMaterial

func _ready():
	base_position = position
	body_entered.connect(_on_body_entered)

func _on_extend_spikes_():
	# Instantly move for now; later animate
	position = base_position + Vector2(0, -extend_distance)

func _on_body_entered(body):
	emit_signal("touched_spike", body)

func reset_spikes():
	position = base_position
	scale.y = 1.0

	if shader:
		shader.set_shader_parameter("extension", 0.0)

func extend():
	var h = sprite.texture.get_height()
	scale.y = 1.0 + (extend_distance / h)
	position.y = base_position.y - h * (scale.y - 1)

func retract():
	scale.y = 1.0
	position.y = 0
	position = base_position

func _on_change_spikestate(new_state):
	if new_state == 1:
		extend()
	else:
		retract()

	if shader:
		shader.set_shader_parameter("extension", extend_distance if new_state == 1 else 0.0)
