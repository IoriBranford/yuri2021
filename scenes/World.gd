extends Spatial

const MOVE_SPEED = 5

var move_dir = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	$MagicGirl.player = $Player
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
