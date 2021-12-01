extends KinematicBody

export var MOVE_SPEED = 5
export var KNOCK_TIME = 1

onready var knock_timer = $Knockback

var move_dir = Vector3.ZERO
var in_knockback = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if in_knockback:
		move_dir = Vector3.BACK
	else:
		move_dir = Vector3.ZERO
		if Input.is_action_pressed("ui_left"):
			move_dir += Vector3.BACK
		if Input.is_action_pressed("ui_right"):
			move_dir += Vector3.FORWARD
		if Input.is_action_pressed("ui_up"):
			move_dir += Vector3.LEFT
		if Input.is_action_pressed("ui_down"):
			move_dir += Vector3.RIGHT
	move_dir = move_dir.normalized() * MOVE_SPEED
	move_and_slide(move_dir, Vector3.UP)

func knockback():
	in_knockback = true
	knock_timer.start(KNOCK_TIME)

func _on_Knockback_timeout():
	in_knockback = false
	knock_timer.stop()
