extends BaseInteractable
class_name InteractableDoor

@export var requires_key := false
@export var key_item_name := "key"

@export var new_area: PackedScene = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var status_msg: Label = $StatusMessage
@onready var status_timer: Timer = $StatusTimer

@onready var player_enter_detector: Area2D = $PlayerEnterDetector 

var player_in_front := false
var player_ref = null

var is_open := false
func _ready():
	super._ready()
	interaction_prompt = "Press F to open door"
	status_timer.timeout.connect(_on_StatusTimer_timeout)
	update_visual()
	player_enter_detector.body_entered.connect(_on_area_body_entered)
	player_enter_detector.body_exited.connect(_on_area_body_exited)

func _on_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_front = true
		player_ref = body

func _on_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_front = false
		player_ref = null

func _process(delta):
	if player_in_front and Input.is_action_just_pressed("ui_up") and new_area != null:
		print("NARNIA")
		get_tree().change_scene_to_packed(new_area)

func _on_interact(player):
	if requires_key:
		# TODO IMPLEMENT Inventory?
		if not player_has_key(player):
			show_message("This door appears to be locked!")
			return
	
	toggle_door()

func _on_StatusTimer_timeout():
	status_msg.text = ""

func toggle_door():
	is_open = not is_open
	current_state = 1 if is_open else 0
	state_changed.emit(current_state)
	update_visual()

func update_visual():
	if sprite:
		if is_open:
			sprite.texture = preload("res://World/Props/door-opened.png")
		else:
			sprite.texture = preload("res://World/Props/door.png")

func player_has_key(player) -> bool:
	# TODO Implement later, maybe singleton?
	return false
	return true

func show_message(text: String, duration: float = 2.0):
	status_msg.text = text
	status_timer.wait_time = duration
	status_timer.one_shot = true
	status_timer.start()
