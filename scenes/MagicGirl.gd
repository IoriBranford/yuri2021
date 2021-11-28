extends KinematicBody

enum MagGirlState {PATROL, SEARCH, CHASE, ENGAGE}

const MOVE_SPEED = 2

onready var mesh = $Mesh

var move_dir = Vector3.BACK
var think_time = 5.0
var state = MagGirlState.PATROL
var alert = 0.0
var player = null
var target_in_cone = false
var target_los = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$ThinkTimer.start(think_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	target_los = check_los()
	$MeshInstance.visible = target_in_cone
	$MeshInstance2.visible = target_los
	match state:
		MagGirlState.PATROL:
			mesh.material_override.albedo_color = Color(0, 0, 1)
			move_and_slide(move_dir * MOVE_SPEED)
			if target_in_cone && target_los:
				state = MagGirlState.SEARCH
		MagGirlState.SEARCH:
			mesh.material_override.albedo_color = Color(1, (100 - alert)/100, 0)
			if target_in_cone && target_los:
				alert += 1.0
			else:
				alert = 0
				state = MagGirlState.PATROL
			if alert > 100:
				state = MagGirlState.CHASE
		MagGirlState.CHASE:
			mesh.material_override.albedo_color = Color(1, 0, 0)
		MagGirlState.ENGAGE:
			mesh.material_override.albedo_color = Color(1, 1, 1)

func check_los():
	var from = global_transform.origin
	var to = player.global_transform.origin + Vector3.UP
	var space_state = get_world().direct_space_state
	var raycast = space_state.intersect_ray(from, to, [self, player], 1)
	return raycast.empty()

func _on_ThinkTimer_timeout():
	move_dir = move_dir * -1
	$ThinkTimer.start(think_time)

func _on_SightArea_body_entered(body):
	target_in_cone = (body == player)

func _on_SightArea_body_exited(body):
	if body == player:
		target_in_cone = false
