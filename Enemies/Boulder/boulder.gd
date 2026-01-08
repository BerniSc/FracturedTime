extends RigidBody2D
class_name Boulder

signal touched_boulder(boulder)

@export var start_frozen := true
@export var initial_impulse := Vector2(10, 0)
@export var can_kill := true

@onready var detector: Area2D = $PlayerCollisionArea

@export var scale_factor := 1.0

@export var rewind_death: bool = true

var is_rolling := false

func _ready():
	add_to_group("boulder")
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = start_frozen
	detector.body_entered.connect(_on_detector_body_entered)

	if scale_factor != 1.0:
		_apply_scaling()

func _apply_scaling():
	var texture_rect = $TextureRect
	var main_collision = $CollisionShape2D
	var area_collision = $PlayerCollisionArea/PlayerCollider
	
	# Scale visual its position to keep centered
	texture_rect.scale = Vector2(scale_factor, scale_factor)
	texture_rect.position = Vector2(-12.0, -12.0) * scale_factor
	
	# Duplicate and scale shapes
	if main_collision.shape:
		main_collision.shape = main_collision.shape.duplicate()
		main_collision.apply_scale(Vector2(scale_factor, scale_factor))
	
	if area_collision.shape:
		area_collision.shape = area_collision.shape.duplicate()
		area_collision.apply_scale(Vector2(scale_factor, scale_factor))

func _on_detector_body_entered(body):
	# Only player connected, no need to check if touched body is player
	# TODO good style this way? Rethink!
	call_deferred("emit_signal", "touched_boulder", self)

func _on_external_trigger(trigger_state):
	print("TriggerState: ", trigger_state)
	if(trigger_state == 1.0):
		trigger()
	else:
		stop()

func will_kill():
	return linear_velocity.length() > 1.0 and can_kill

func trigger():
	if not is_rolling:
		print("Applied Impulse")
		
		# Force complete physics reset to handle timing from non-physics interactions (trigger-zone f.e.)
		# Without this the states get desynchronzied and the engine treats the boulder as frozen no matter its actual state
		freeze = true
		await get_tree().process_frame
		freeze = false
		await get_tree().process_frame
		
		sleeping = false
		
		apply_impulse(initial_impulse)
		is_rolling = true
		
func _physics_process(delta):
	if not freeze and linear_velocity.length() > 1.0:
		self.is_rolling = true
	else:
		is_rolling = false

func stop():
	freeze = true
	is_rolling = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
