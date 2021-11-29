extends Spatial

const MOVE_SPEED = 5

var move_dir = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	$MagicGirl.connect("patrol_done", self, "new_patrol")
	$MagicGirl.player = $Player
	$Hud.mag_girl = $MagicGirl
	$NextPatrol.start((randi() % 3) + 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$DebugLabel.text = "Time to next patrol: " + str($NextPatrol.time_left)
	move_dir = Vector3.ZERO
#	if Input.is_action_just_pressed("ui_select"):
#		var new_dialog = Dialogic.start("Intro")
#		add_child(new_dialog)
	if Input.is_action_pressed("ui_left"):
		move_dir += Vector3.BACK
	if Input.is_action_pressed("ui_right"):
		move_dir += Vector3.FORWARD
	if Input.is_action_pressed("ui_up"):
		move_dir += Vector3.LEFT
	if Input.is_action_pressed("ui_down"):
		move_dir += Vector3.RIGHT
	move_dir = move_dir.normalized() * MOVE_SPEED
	$Player.move_and_slide(move_dir, Vector3.UP)
	$CamBase.translation = $Player.translation

func new_patrol():
	$NextPatrol.start((randi() % 3) + 1)

func _on_NextPatrol_timeout():
	$NextPatrol.stop()
	$MagicGirl.fly_in(Vector3(-3, 4, 0), 5, 10)
