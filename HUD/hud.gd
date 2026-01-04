extends Control

@export var frame_scene: PackedScene
@onready var canvas_layer = $CanvasLayer

enum SlotState { EMPTY, IN_PROGRESS, ACTIVE }

var frame_nodes = []
var slot_states = []
var selected_slot := GameSettings.MAX_CLONES - 1

func _ready():
	var max_clones = GameSettings.MAX_CLONES
	var spacing = 2

	# Measure frame size
	var temp_frame = frame_scene.instantiate()
	canvas_layer.add_child(temp_frame)
	# await temp_frame.ready  # Wait for the node to be fully ready
	await get_tree().process_frame
	var frame_size = temp_frame.size
	print(frame_size)
	remove_child(temp_frame)
	temp_frame.queue_free()

	# Create frames
	for i in range(max_clones):
		var frame = frame_scene.instantiate()
		canvas_layer.add_child(frame)
		frame.anchor_right = 1
		frame.anchor_top = 0
		frame.anchor_bottom = 0
		frame.anchor_left = 1
		frame.offset_right = - (i * (frame_size.x + spacing))
		frame.offset_left = frame.offset_right - frame_size.x
		frame.offset_top = 8
		frame.offset_bottom = frame.offset_top + frame_size.y
		frame.pivot_offset = Vector2(frame_size.x/2, 0)
		var label = frame.find_child("Label")
		label.text = str(GameSettings.MAX_CLONES - i)
		frame_nodes.append(frame)
		slot_states.append(SlotState.EMPTY)
	update_frames()

func _on_branch_began(slot_idx):
	slot_states[slot_idx] = SlotState.IN_PROGRESS
	update_frames()
	
func _on_branch_finished(branch_player, buffer, end_position, selected_slot_idx):
	slot_states[selected_slot_idx] = SlotState.ACTIVE
	update_frames()
	
func set_slot_occupied(index, occupied):
	slot_states[index] = SlotState.ACTIVE if occupied else SlotState.EMPTY
	update_frames()

func select_slot(index):
	selected_slot = GameSettings.MAX_CLONES - clamp(index, 0, frame_nodes.size() - 1) - 1
	update_frames()

func update_frames():
	for i in range(frame_nodes.size()):
		frame_nodes[i].scale = Vector2(1.2, 1.2) if i == selected_slot else Vector2(1, 1)
		# Dim if slot is empty
		frame_nodes[i].self_modulate = Color(1, 1, 1, 1) if slot_states[i] else Color(0.5, 0.5, 0.5, 1)
		
		var player_sprite = frame_nodes[i].get_node("Frame/PlayerSprite")	# animatedSprite2D
		match slot_states[i]:
			SlotState.EMPTY:
				player_sprite.visible = false
				frame_nodes[i].self_modulate = Color(0.5, 0.5, 0.5, 1)
			SlotState.IN_PROGRESS:
				player_sprite.visible = true
				player_sprite.animation = "idle"
				player_sprite.modulate = Color(0.5, 0.5, 0.5, 1) # Greyed out
				frame_nodes[i].self_modulate = Color(1, 1, 1, 1)
			SlotState.ACTIVE:
				player_sprite.visible = true
				player_sprite.animation = "run"
				player_sprite.modulate = Color(1, 1, 1, 1) # Full color
				frame_nodes[i].self_modulate = Color(1, 1, 1, 1)

func _input(event):
	if event is InputEventKey and event.pressed:
		# Check if key is numberkey (1-9)
		var key_num = event.keycode - KEY_1
		if key_num >= 0 and key_num < frame_nodes.size():
			select_slot(key_num)
