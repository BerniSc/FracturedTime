extends Area2D

@export_category("Hint-Area")
@export var hint_duration := 2.0
@export_multiline var hint_text := ""
@export var sign_font: FontFile
@export var text_size := 14
@export var position_modificator_x := -50
@export var position_modificator_y := -100

@export_category("Var-Setter-Area")
@export var target_node: NodePath
@export var target_var: String
@export var var_value_on_enter: Variant = true
@export var var_value_on_exit: Variant = false

@onready var timer: Timer = $Timer

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func show_text_popup(text: String):
	var popup = Label.new()
	popup.text = text
	if sign_font:
		popup.add_theme_font_override("font", sign_font)
	popup.add_theme_font_size_override("font_size", text_size)
	popup.add_theme_color_override("font_color", Color.WHITE)
	popup.add_theme_color_override("font_shadow_color", Color.BLACK)
	popup.add_theme_constant_override("shadow_offset_x", 1)
	popup.add_theme_constant_override("shadow_offset_y", 1)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.position = global_position + Vector2(position_modificator_x, position_modificator_y)
	get_tree().current_scene.add_child(popup)

	# Remove popup after hint_duration seconds
	var popup_timer := Timer.new()
	popup_timer.wait_time = hint_duration
	popup_timer.one_shot = true
	popup_timer.connect("timeout", Callable(popup, "queue_free"))
	get_tree().current_scene.add_child(popup_timer)
	popup_timer.start()

func _on_body_entered(body):
	if body.is_in_group("player"):
		_set_target_var(var_value_on_enter)
		show_text_popup(hint_text)

func _on_body_exited(body):
	if body.is_in_group("player"):
		_set_target_var(var_value_on_exit)

func _set_target_var(value):
	var node = get_node_or_null(target_node)
	if node and target_var != "":
		node.set(target_var, value)
