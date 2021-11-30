extends Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player.add_to_group("player")
	$MagicGirl.connect("patrol_done", self, "new_patrol")
	$Hud.mag_girl = $MagicGirl
	$NextPatrol.start((randi() % 3) + 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$DebugLabel.text = "Time to next patrol: " + str($NextPatrol.time_left)
#	if Input.is_action_just_pressed("ui_select"):
#		var new_dialog = Dialogic.start("Intro")
#		add_child(new_dialog)
	$CamBase.translation = $Player.translation

func new_patrol():
	$NextPatrol.start((randi() % 3) + 1)

func _on_NextPatrol_timeout():
	$NextPatrol.stop()
	$MagicGirl.fly_in(Vector3(-3, 2, 0), 5, 15)
