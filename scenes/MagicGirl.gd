extends KinematicBody

enum MagGirlState {IDLE, FLY_IN, PATROL, SEARCH, CHASE, FLY_OUT}

export var MOVE_SPEED = 4
export var ALERT_RATE = 1.0
export var HOME_POS = Vector3(0, 10, 0)

signal patrol_done

onready var mesh = $Mesh
onready var patrol_timer = $PatrolTimer

var move_dir = Vector3.FORWARD
var think_time = 5.0
var state = MagGirlState.IDLE
var alert = 0.0
var player = null
var patrol_time = 10
var patrol_length = 5
var patrol_point = Vector3.ZERO
var start_pos = Vector3.ZERO
var target_in_cone = false
var target_los = false

# Called when the node enters the scene tree for the first time.
func _ready():
	global_transform.origin = HOME_POS
	patrol_timer.start(patrol_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match state:
		MagGirlState.FLY_IN:
			if global_transform.origin == start_pos:
				patrol_point = global_transform.origin + move_dir * patrol_length
				patrol_timer.start(patrol_time)
				state = MagGirlState.PATROL
			else:
				global_transform.origin = global_transform.origin.move_toward(start_pos, delta * MOVE_SPEED)
		MagGirlState.PATROL:
			target_los = check_los()
			mesh.material_override.albedo_color = Color(0, 0, 1)
			global_transform.origin = global_transform.origin.move_toward(patrol_point, delta * MOVE_SPEED)
			if global_transform.origin == patrol_point:
				global_transform.origin = patrol_point
				move_dir = -move_dir
				patrol_point = global_transform.origin + move_dir * patrol_length
			if target_in_cone && target_los:
				patrol_timer.paused = true
				state = MagGirlState.SEARCH
		MagGirlState.SEARCH:
			target_los = check_los()
			mesh.material_override.albedo_color = Color(1, (100 - alert)/100, 0)
			if target_in_cone && target_los:
				alert += ALERT_RATE
			else:
				alert = 0
				patrol_timer.paused = false
				state = MagGirlState.PATROL
			if alert > 100:
				state = MagGirlState.CHASE
		MagGirlState.CHASE:
			mesh.material_override.albedo_color = Color(1, 0, 0)
		MagGirlState.FLY_OUT:
			if global_transform.origin == HOME_POS:
				global_transform.origin = HOME_POS
				state = MagGirlState.IDLE
				emit_signal("patrol_done")
			else:
				global_transform.origin = global_transform.origin.move_toward(HOME_POS, delta * MOVE_SPEED)

func shoot():
	pass

func check_los():
	var from = global_transform.origin
	var to = player.global_transform.origin + Vector3.UP
	var space_state = get_world().direct_space_state
	var raycast = space_state.intersect_ray(from, to, [self, player], 1)
	return raycast.empty()

func fly_in(pos, time, length):
	print("Flying in...")
	patrol_length = length
	patrol_time = time
	start_pos = pos
	state = MagGirlState.FLY_IN

func _on_SightArea_body_entered(body):
	target_in_cone = (body == player)

func _on_SightArea_body_exited(body):
	if body == player:
		target_in_cone = false

func _on_PatrolTimer_timeout():
	patrol_timer.stop()
	state = MagGirlState.FLY_OUT

func _on_AttackTimer_timeout():
	pass # Replace with function body.
