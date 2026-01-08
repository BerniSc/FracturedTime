extends BaseInteractable

@export var player_trigger_threshhold := 1

# If this triggerzone is used to kill we can connect to this signal here
signal touched_deathzone(deathzone)
@export var rewind_death: bool = true

var _player_cnt := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		_player_cnt += 1
		if _player_cnt >= player_trigger_threshhold:
			print("Trigger")
			set_state(true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		_player_cnt -= 1
		if _player_cnt < player_trigger_threshhold:
			set_state(false)

func set_state(new_state: bool):
	current_state = 1.0 if new_state else 0
	state_changed.emit(current_state)
	if current_state: 
		touched_deathzone.emit(self)
