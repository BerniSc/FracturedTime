extends Area2D
class_name BaseInteractable

# Emit here, just contains the player
signal interacted(player)
# Emitted in subclass, contains state and other informations
signal state_changed(new_state)

@export var interaction_prompt := "Press F to interact"
@export var is_one_time_use := false
@export var requires_player_input := true

var is_player_in_range := false
var has_been_used := false
var current_state := 0

@onready var prompt_label: Label = $PromptLabel

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if prompt_label:
		prompt_label.text = interaction_prompt
		prompt_label.visible = false

func _input(event):
	if is_player_in_range and event.is_action_pressed("ui_interact"):
		interact()

func _on_body_entered(body):
	# Simple check if it's the player
	if body.has_method("set_current_interactable"):
		body.set_current_interactable(self)
		is_player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	# Simple check if it's the player
	if body.has_method("clear_current_interactable"):
		body.clear_current_interactable(self)
		is_player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func interact():
	if has_been_used and is_one_time_use:
		return
	
	var player = get_overlapping_bodies()[0] if get_overlapping_bodies().size() > 0 else null
	if player:
		_on_interact(player)
		interacted.emit(player)
		
		if is_one_time_use:
			has_been_used = true

# Override in child classes
func _on_interact(player):
	print("Base interaction")
