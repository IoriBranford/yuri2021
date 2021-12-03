extends KinematicBody

export var MOVE_SPEED = 3
export var KNOCK_TIME = 1

const COLL_KAIJU = {"translate":Vector3(0, 1.75, 0), "radius":1, "height":1.5}
const COLL_HUMAN = {"translate":Vector3(0, 0.875, 0), "radius":0.75, "height":0.25}

onready var knock_timer = $Knockback
onready var collision = $PlayerCollision

var obj_melee = preload("res://scenes/MeleeAttack.tscn")
var move_dir = Vector3.ZERO
var in_knockback = false
var is_transformed = false

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
	if move_dir != Vector3.ZERO:
		look_at(global_transform.origin + move_dir.normalized(), Vector3.UP)
		move_dir = move_dir.normalized() * MOVE_SPEED
		move_and_slide(move_dir, Vector3.UP)

func melee_attack():
	var inst_melee = obj_melee.instance()
	add_child(inst_melee)
	inst_melee.translation = Vector3(0, 1, -3)

func change_form():
	is_transformed = !is_transformed
	$SmokePuff.emitting = true
	$HumanForm.visible = is_transformed
	$KaijuForm.visible = !is_transformed
	if is_transformed:
		collision.translation = COLL_HUMAN.translate
		collision.shape.radius = COLL_HUMAN.radius
		collision.shape.height = COLL_HUMAN.height
	else:
		collision.translation = COLL_KAIJU.translate
		collision.shape.radius = COLL_KAIJU.radius
		collision.shape.height = COLL_KAIJU.height

func knockback():
	in_knockback = true
	knock_timer.start(KNOCK_TIME)

func _on_Knockback_timeout():
	in_knockback = false
	knock_timer.stop()
