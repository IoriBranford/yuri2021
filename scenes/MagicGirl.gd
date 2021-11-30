extends KinematicBody

enum MagGirlState {IDLE, FLY_IN, PATROL, SEARCH, CHASE, FLY_OUT}

# Editor vars
export var MOVE_SPEED = 4
export var ALERT_RATE = 1.0
export var FIRE_RATE = 2.0
export var HOME_POS = Vector3(0, 10, 0)
export var FRONT_DEPTH = 0
export var ENGAGE_DISTANCE = 6

signal patrol_done

# Accessor vars
onready var res = $Resources
onready var mesh = $Mesh
onready var patrol_timer = $PatrolTimer
onready var attack_timer = $AttackTimer
onready var voice = $Voice

var obj_bullet = preload("res://scenes/PushWave.tscn")
var move_dir = Vector3.FORWARD
var think_time = 5.0
var state = MagGirlState.IDLE
var alert = 0.0
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
				$SightCone.visible = true
				mesh.material_override.albedo_color = Color(0, 0, 1)
				state = MagGirlState.PATROL
			else:
				global_transform.origin = global_transform.origin.move_toward(start_pos, delta * MOVE_SPEED)
		MagGirlState.PATROL:
			target_los = check_los()
			global_transform.origin = global_transform.origin.move_toward(patrol_point, delta * MOVE_SPEED)
			if global_transform.origin == patrol_point:
				move_dir = -move_dir
				patrol_point = global_transform.origin + move_dir * patrol_length
			if target_in_cone && target_los:
				patrol_timer.paused = true
				mesh.material_override.albedo_color = Color(1, 1, 0)
				state = MagGirlState.SEARCH
		MagGirlState.SEARCH:
			target_los = check_los()
			if target_in_cone && target_los:
				alert += ALERT_RATE
			else:
				alert = 0
				patrol_timer.paused = false
				state = MagGirlState.PATROL
			if alert > 100:
				voice.stream = res.get_resource("predictabo")
				voice.play()
				$SightCone.visible = false
				attack_timer.start(FIRE_RATE)
				mesh.material_override.albedo_color = Color(1, 0, 0)
				state = MagGirlState.CHASE
		MagGirlState.CHASE:
			var my_pos = global_transform.origin
			var player_pos = get_tree().get_nodes_in_group("player")[0].global_transform.origin
			var move_to = player_pos + Vector3.FORWARD * ENGAGE_DISTANCE
			move_to.x = FRONT_DEPTH
			if my_pos.x != FRONT_DEPTH:
				global_transform.origin = my_pos.move_toward(move_to, delta * MOVE_SPEED * 2)
			elif abs(player_pos.z - my_pos.z) > ENGAGE_DISTANCE:
				global_transform.origin = my_pos.move_toward(move_to, delta * MOVE_SPEED)
		MagGirlState.FLY_OUT:
			if global_transform.origin == HOME_POS:
				global_transform.origin = HOME_POS
				state = MagGirlState.IDLE
				emit_signal("patrol_done")
			else:
				global_transform.origin = global_transform.origin.move_toward(HOME_POS, delta * MOVE_SPEED)

func shoot():
	voice.stream = res.get_resource("reppuken")
	voice.play()
	var inst_bullet = obj_bullet.instance()
	add_child(inst_bullet)
	inst_bullet.move_dir = Vector3.BACK

func check_los():
	var player = get_tree().get_nodes_in_group("player")[0]
	if player != null:
		var from = global_transform.origin
		var to = player.global_transform.origin + Vector3.UP
		var space_state = get_world().direct_space_state
		var raycast = space_state.intersect_ray(from, to, [self, player], 1)
		return raycast.empty()
	else:
		return false

func fly_in(pos, time, length):
	voice.stream = res.get_resource("noescape")
	voice.play()
	patrol_length = length
	patrol_time = time
	start_pos = pos
	state = MagGirlState.FLY_IN

func _on_SightArea_body_entered(body):
	target_in_cone = body.is_in_group("player")

func _on_SightArea_body_exited(body):
	if body.is_in_group("player"):
		target_in_cone = false

func _on_PatrolTimer_timeout():
	patrol_timer.stop()
	$SightCone.visible = false
	mesh.material_override.albedo_color = Color(1, 1, 1)
	state = MagGirlState.FLY_OUT

func _on_AttackTimer_timeout():
	var my_pos = global_transform.origin
	var player_pos = get_tree().get_nodes_in_group("player")[0].global_transform.origin
	if (global_transform.origin.x == FRONT_DEPTH && 
	abs(player_pos.z - my_pos.z) <= ENGAGE_DISTANCE):
		shoot()
