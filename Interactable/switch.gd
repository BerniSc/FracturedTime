extends BaseInteractable
class_name InteractableSwitch

@export var is_toggle := true
@export var auto_reset_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
var is_activated := false
var reset_timer := 0.0

func _ready():
	super._ready()
	update_visual()

func _process(delta):
	if auto_reset_time > 0 and is_activated:
		reset_timer += delta
		if reset_timer >= auto_reset_time:
			set_state(false)
			reset_timer = 0.0

func _on_interact(player):
	if is_toggle:
		set_state(not is_activated)
	else:
		set_state(true)
		if auto_reset_time > 0:
			reset_timer = 0.0

func set_state(new_state: bool):
	is_activated = new_state
	current_state = 1 if is_activated else 0
	state_changed.emit(current_state)
	update_visual()

func update_visual():
	if sprite:
		if is_activated:
			sprite.texture = preload("res://World/Props/crank-up.png")
		else:
			sprite.texture = preload("res://World/Props/crank-down.png")
