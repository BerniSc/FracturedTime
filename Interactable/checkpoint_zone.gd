extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("ENTERED CP ZONE")
	if body.is_in_group("player"):
		print("SET CHECKPOINT: ", body.global_position)
		GameState.checkpoint_position = body.global_position
		print("CP is: ", GameState.checkpoint_position)
