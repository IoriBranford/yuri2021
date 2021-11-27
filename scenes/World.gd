extends Spatial

var move_dir = Vector3.ZERO
var hunter_dir = Vector3.FORWARD
var think_time = 5.0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Hunter/HunterThink.start(think_time)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_dir = Vector3.ZERO
	if Input.is_action_pressed("ui_left"):
		move_dir += Vector3.BACK
	if Input.is_action_pressed("ui_right"):
		move_dir += Vector3.FORWARD
	if Input.is_action_pressed("ui_up"):
		move_dir += Vector3.LEFT
	if Input.is_action_pressed("ui_down"):
		move_dir += Vector3.RIGHT
	move_dir = move_dir.normalized()
	$Player.move_and_slide(move_dir * 5, Vector3.UP)
	$CamBase.translation = $Player.translation
	$Hunter.move_and_slide(hunter_dir * 4)

func _on_HunterThink_timeout():
	hunter_dir = hunter_dir * -1
	$Hunter/HunterThink.start(think_time)
