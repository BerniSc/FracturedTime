extends RigidBody2D
class_name Boulder

signal touched_boulder(boulder)

@export var initial_impulse := Vector2(10, 0)
@export var can_kill := true

@onready var detector: Area2D = $PlayerCollisionArea

var is_rolling := false

func _ready():
	add_to_group("boulder")
	freeze = true
	detector.body_entered.connect(_on_detector_body_entered)

func _on_detector_body_entered(body):
	emit_signal("touched_boulder", self)

func _on_external_trigger(trigger_state):
	if(trigger_state == 1.0):
		trigger()
	else:
		stop()

func trigger():
	if not is_rolling:
		print("Applied Impulse")
		freeze = false
		apply_impulse(initial_impulse)
		is_rolling = true
		
func _physics_process(delta):
	if not freeze and linear_velocity.length() > 10.0:
		is_rolling = true
	else:
		is_rolling = false

func stop():
	freeze = true
	is_rolling = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
