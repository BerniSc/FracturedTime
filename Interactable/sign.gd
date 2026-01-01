extends BaseInteractable
class_name InteractableSign

@export_multiline var sign_text := "Hello, World!"
@export var text_display_time := 3.0
@export var sign_font: FontFile
@export var text_size := 14

func _ready():
	super._ready()
	interaction_prompt = "Press F to read"

func _on_interact(player):
	show_text_popup(sign_text)

func show_text_popup(text: String):
	# Create a simple text popup
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
	popup.position = global_position + Vector2(-50, -100)
	get_tree().current_scene.add_child(popup)
	
	# Remove popup after text_display_time seconds
	var timer = Timer.new()
	timer.wait_time = text_display_time
	timer.one_shot = true
	timer.connect("timeout", Callable(popup, "queue_free"))
	get_tree().current_scene.add_child(timer)
	timer.start()
