extends Spatial

enum WorldState {START, ACTIVE, CUTSCENE, END}

onready var hud = $Hud

var state = WorldState.START setget set_state

func set_state(value):
	match value:
		WorldState.START:
			$NextPatrol.stop()
		WorldState.CUTSCENE:
			pass
		WorldState.ACTIVE:
			$NextPatrol.start((randi() % 3) + 1)
		WorldState.END:
			$NextPatrol.stop()
			$Hud/BigMessage.visible = true
	state = value

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player.add_to_group("player")
	$Player.connect("ejected", self, "cutscene_eject")
	$MagicGirl.add_to_group("enemy")
	$MagicGirl.connect("patrol_done", self, "new_patrol")
	$MagicGirl.connect("update_hud", $Hud, "update_alert")

func _physics_process(delta):
	$DebugLabel.text = "Time to next patrol: " + str($NextPatrol.time_left)
	$CamBase.translation = $Player.translation
	match state:
		WorldState.START, WorldState.ACTIVE:
			$Player.move_player()
		WorldState.CUTSCENE:
			pass
		WorldState.END:
			if Input.is_action_just_pressed("player_attack"):
				get_tree().reload_current_scene()

func new_patrol():
	if state == WorldState.ACTIVE:
		$NextPatrol.start((randi() % 3) + 1)

func cutscene_eject():
	self.state = WorldState.CUTSCENE
	$MagicGirl.state = $MagicGirl.MagGirlState.IDLE
	var new_dialog = Dialogic.start("Micah Eject")
	add_child(new_dialog)
	yield(new_dialog, "timeline_end")
	$MagicGirl.fly_out()
	self.state = WorldState.START

func cutscene_ending():
	self.state = WorldState.CUTSCENE
	$MagicGirl.fly_out()
	var new_dialog = Dialogic.start("Ending")
	add_child(new_dialog)
	yield(new_dialog, "timeline_end")
	self.state = WorldState.END

func _on_NextPatrol_timeout():
	$NextPatrol.stop()
	$MagicGirl.fly_in(Vector3(-3, 2, $Player.global_transform.origin.z), 15, 5)

func _on_OceanEnd_body_exited(body):
	if body.is_in_group("player"):
		if body.translation.z >= $OceanEnd.translation.z:
			cutscene_eject()
		elif body.translation.z < $OceanEnd.translation.z:
			self.state = WorldState.ACTIVE

func _on_FinishLine_body_exited(body):
	if body.is_in_group("player"):
		if body.translation.z >= $OceanEnd.translation.z:
			self.state = WorldState.ACTIVE
		elif body.translation.z < $OceanEnd.translation.z:
			cutscene_ending()
