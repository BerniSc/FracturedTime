extends Node2D

@export var fade_time := 0.5
var elapsed := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func setup(texture: Texture2D, region: Rect2, flip_h: bool, offset: Vector2):
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.flip_h = flip_h
	sprite.modulate.a = 0.6
	sprite.position = offset


func _process(delta):
	elapsed += delta
	sprite.modulate.a = lerp(0.6, 0.0, elapsed / fade_time)
	if elapsed >= fade_time:
		queue_free()
