extends KinematicBody

enum MagGirlState {IDLE, FLY_IN, PATROL, SEARCH, CHASE, FLY_OUT, SWATTED}

# Editor vars
export var MOVE_SPEED = 4
export var ALERT_RATE = 1.0
export var FIRE_RATE = 2.0
export var FRONT_DEPTH = 0
export var ENGAGE_DISTANCE = 6

signal patrol_done
signal update_hud()

# Accessor vars
onready var res = $Resources
onready var mesh = $Mesh
onready var patrol_timer = $PatrolTimer
onready var attack_timer = $AttackTimer
onready var voice = $Voice

var obj_bullet = preload("res://scenes/PushWave.tscn")
var move_dir = Vector3.FORWARD
var think_time = 5.0
var state = MagGirlState.IDLE setget set_state
var alert = 0.0
var patrol_time = 10
var patrol_length = 5
var patrol_point = Vector3.ZERO
var home_pos = Vector3(0, 10, 0)
var start_pos = Vector3.ZERO
var target_in_cone = false
var target_los = false

func set_state(value):
	match value:
		MagGirlState.PATROL:
			alert = 0
			mesh.material_override.albedo_color = Color(0, 0, 1)
			$SightCone.visible = true
		MagGirlState.SEARCH:
			mesh.material_override.albedo_color = Color(1, 1, 0)
			$SightCone.visible = true
		MagGirlState.CHASE:
			mesh.material_override.albedo_color = Color(1, 0, 0)
			$SightCone.visible = false
		_:
			patrol_timer.stop()
			attack_timer.stop()
			mesh.material_override.albedo_color = Color(1, 1, 1)
			$SightCone.visible = false
	state = value
	emit_signal("update_hud", self)

# Called when the node enters the scene tree for the first time.
func _ready():
	global_transform.origin = home_pos
	patrol_timer.start(patrol_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match state:
		MagGirlState.FLY_IN:
			if global_transform.origin == start_pos:
				patrol_point = global_transform.origin + move_dir * patrol_length
				patrol_timer.start(patrol_time)
				self.state = MagGirlState.PATROL
			else:
				global_transform.origin = global_transform.origin.move_toward(start_pos, delta * MOVE_SPEED * 2)
		MagGirlState.PATROL:
			target_los = check_los()
			global_transform.origin = global_transform.origin.move_toward(patrol_point, delta * MOVE_SPEED)
			if global_transform.origin == patrol_point:
				move_dir = -move_dir
				patrol_point = global_transform.origin + move_dir * patrol_length
			if target_in_cone && target_los:
				patrol_timer.paused = true
				self.state = MagGirlState.SEARCH
		MagGirlState.SEARCH:
			target_los = check_los()
			if target_in_cone && target_los:
				alert += ALERT_RATE
			else:
				patrol_timer.paused = false
				self.state = MagGirlState.PATROL
			if alert >= 100:
				voice.stream = res.get_resource("predictabo")
				voice.play()
				attack_timer.start(FIRE_RATE)
				self.state = MagGirlState.CHASE
			else:
				emit_signal("update_hud", self)
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
			if global_transform.origin == home_pos:
				self.state = MagGirlState.IDLE
				emit_signal("patrol_done")
			else:
				global_transform.origin = global_transform.origin.move_toward(home_pos, delta * MOVE_SPEED * 2)
		MagGirlState.SWATTED:
			if global_transform.origin == home_pos:
				mesh.rotation_degrees = Vector3(-90, 0, 0)
				self.state = MagGirlState.IDLE
				emit_signal("patrol_done")
			else:
				var rand_vector = Vector3(randf()-0.5, randf()-0.5, randf()-0.5).normalized()
				mesh.rotate_object_local(rand_vector, PI)
				global_transform.origin = global_transform.origin.move_toward(home_pos, delta * MOVE_SPEED * 2)

func shoot():
	voice.stream = res.get_resource("reppuken")
	voice.play()
	var inst_bullet = obj_bullet.instance()
	add_child(inst_bullet)
	inst_bullet.move_dir = Vector3.BACK

func check_los():
	var player = get_tree().get_nodes_in_group("player")[0]
	if player != null:
		var from = $SightPoint.global_transform.origin
		var to = player.global_transform.origin + Vector3.UP
		var space_state = get_world().direct_space_state
		var raycast = space_state.intersect_ray(from, to, [self, player], 1)
		return raycast.empty()
	else:
		return false

func swat():
	patrol_timer.stop()
	self.state = MagGirlState.SWATTED

func fly_in(pos, time, length):
	voice.stream = res.get_resource("noescape")
	voice.play()
	patrol_length = length
	patrol_time = time
	start_pos = pos
	self.state = MagGirlState.FLY_IN

func fly_out():
	self.state = MagGirlState.FLY_OUT

func _on_SightArea_body_entered(body):
	target_in_cone = body.is_in_group("player")

func _on_SightArea_body_exited(body):
	if body.is_in_group("player"):
		target_in_cone = false

func _on_PatrolTimer_timeout():
	fly_out()

func _on_AttackTimer_timeout():
	var my_pos = global_transform.origin
	var player_pos = get_tree().get_nodes_in_group("player")[0].global_transform.origin
	if (global_transform.origin.x == FRONT_DEPTH && 
	abs(player_pos.z - my_pos.z) <= ENGAGE_DISTANCE):
		shoot()
