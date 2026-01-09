extends Area2D

@export_group("Teleport")
@export var teleport_boulder := false
@export var clear_momentum := true
@export var delta_pos_x := 0
@export var delta_pos_y := 0

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("BODY ENTERED")
	print(body)
	if body.is_in_group("boulder"):
		if teleport_boulder:
			if clear_momentum: body.linear_velocity = Vector2(0,0)
			body.global_position.x += delta_pos_x
			body.global_position.y += delta_pos_y
			body.show_anim = true
		elif body.has_method("stop"):
			body.stop()
