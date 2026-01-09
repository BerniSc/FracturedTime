extends Node2D

@export var fade_time := 0.5
var elapsed := 0.0

@onready var sprite: Sprite2D = $Sprite2D

var _start_opacity = null

func setup(texture: Texture2D, region: Rect2, flip_h: bool, offset: Vector2, start_opactiy: float = 0.6):
	_start_opacity = start_opactiy
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.flip_h = flip_h
	sprite.modulate.a = _start_opacity
	sprite.position = offset

func _process(delta):
	elapsed += delta
	sprite.modulate.a = lerp(_start_opacity, 0.0, elapsed / fade_time)
	if elapsed >= fade_time:
		queue_free()
