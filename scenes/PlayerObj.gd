extends KinematicBody

export var MOVE_SPEED = 5
export var KNOCK_TIME = 1

signal ejected

onready var knock_timer = $Knockback

var obj_melee = preload("res://scenes/MeleeAttack.tscn")
var move_dir = Vector3.ZERO
var in_knockback = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass

func move_player():
	if in_knockback:
		move_dir = Vector3.BACK
	else:
		move_dir = Vector3.ZERO
		if Input.is_action_just_pressed("player_attack"):
			melee_attack()
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

func melee_attack():
	var inst_melee = obj_melee.instance()
	add_child(inst_melee)
	inst_melee.translation = Vector3(0, 1, -3)

func knockback():
	in_knockback = true
	knock_timer.start(KNOCK_TIME)

func _on_Knockback_timeout():
	in_knockback = false
	knock_timer.stop()
