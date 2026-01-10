extends Area2D

@export var extend_distance: float = 64.0
@export var extend_speed: float = 200.0

var base_position: Vector2
@onready var sprite: Sprite2D = $Sprite2D
@onready var shader = sprite.material as ShaderMaterial

signal touched_spike(body)

func _ready():
	add_to_group("spikes")
	base_position = position
	body_entered.connect(_on_body_entered)
	
	# Initialzustand: Ausgefahren
	extend() 

func _on_body_entered(body):
	emit_signal("touched_spike", body)

func extend():
	var h = sprite.texture.get_height()
	scale.y = 1.0 + (extend_distance / h)
	position.y = base_position.y - (extend_distance) # Vereinfachte Berechnung
	if shader:
		shader.set_shader_parameter("extension", extend_distance)

func retract():
	scale.y = 1.0
	position = base_position
	if shader:
		shader.set_shader_parameter("extension", 0.0)

func _on_change_spikestate(new_state):
	# Wenn Schalter AUS (0) -> Spikes AUSGEFAHREN
	# Wenn Schalter AN (1) -> Spikes EINGEFAHREN
	if new_state == 0:
		extend()
	else:
		retract()
