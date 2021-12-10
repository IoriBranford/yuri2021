extends Spatial

enum WorldState {TITLE, START, ACTIVE, CUTSCENE, FAIL, END}

onready var hud = $Hud
onready var menu_items = [
	$TitleScreen/Main/Menu/Start,
	$TitleScreen/Main/Menu/Sound,
	$TitleScreen/Main/Menu/Credit,
	$TitleScreen/Main/Menu/Quit
]

var menu_index = 0
var state = WorldState.TITLE setget set_state
var sound_on = true

func set_state(value):
	if state == WorldState.CUTSCENE && value != WorldState.CUTSCENE:
		hud.gf_timer.paused = false
	if state == WorldState.TITLE and value != WorldState.TITLE:
		$TitleScreen.visible = false
	match value:
		WorldState.TITLE:
			$TitleScreen.visible = true
			$CreditScreen.visible = false
		WorldState.START:
			$NextPatrol.stop()
		WorldState.CUTSCENE:
			hud.gf_timer.paused = true
		WorldState.ACTIVE:
			$NextPatrol.start((randi() % 3) + 1)
		WorldState.FAIL:
			$NextPatrol.stop()
			$Hud/BigMessage/Label.text = "DATE FAILED"
			$Hud/BigMessage/Label2.text = "Aw man, you blew it!\nPress attack (Z) to try again!"
			$Hud/BigMessage.visible = true
		WorldState.END:
			$NextPatrol.stop()
			$Hud/BigMessage/Label.text = "DATE SUCCESSFUL"
			$Hud/BigMessage/Label2.text = "Hell yeah! You crushed it!\nPress attack (Z) to restart!"
			$Hud/BigMessage.visible = true
	state = value

# Called when the node enters the scene tree for the first time.
func _ready():
	$Hud.connect("girlfriend_timeout", self, "cutscene_fail")
	$Player.add_to_group("player")
	$Player.connect("shop_nearby", $Hud, "_on_Player_shop_nearby")
	$Player.connect("no_shop_nearby", $Hud, "_on_Player_no_shop_nearby")
	$MagicGirl.add_to_group("enemy")
	$MagicGirl.connect("patrol_done", self, "new_patrol")
	$MagicGirl.connect("update_hud", $Hud, "update_alert")
	$MagicGirl.connect("pester", self, "cutscene_pester")
	self.state = WorldState.TITLE

func _physics_process(delta):
	$CamBase.translation = $Player.translation
	match state:
		WorldState.TITLE:
			if Input.is_action_just_pressed("player_attack"):
				if $CreditScreen.visible:
					$CreditScreen.visible = false
				else:
					match menu_index:
						0:
							$TitleScreen.visible = false
							self.state = WorldState.START
							cutscene_intro()
						1:
							sound_on = !sound_on
						2:
							$CreditScreen.visible = true
						3:
							get_tree().quit()
			if Input.is_action_just_pressed("ui_up"):
				menu_index -= 1
			if Input.is_action_just_pressed("ui_down"):
				menu_index += 1
			if menu_index >= menu_items.size():
				menu_index = menu_items.size() - 1 
			if menu_index < 0:
				menu_index = 0
			for i in menu_items.size():
				if i == menu_index:
					menu_items[menu_index].modulate = Color(1,0,0)
				else:
					menu_items[i].modulate = Color(1,1,1)
		WorldState.START, WorldState.ACTIVE:
			$Player.move_player(delta)
		WorldState.CUTSCENE:
			pass
		WorldState.FAIL:
			if Input.is_action_just_pressed("player_attack"):
				get_tree().reload_current_scene()
		WorldState.END:
			if Input.is_action_just_pressed("player_attack"):
				get_tree().reload_current_scene()

func new_patrol():
	if state == WorldState.ACTIVE:
		$NextPatrol.start((randi() % 3) + 1)

func cutscene_intro():
	self.state = WorldState.CUTSCENE
	$MagicGirl.state = $MagicGirl.MagGirlState.IDLE
	var new_dialog = Dialogic.start("Quests Intro")
	add_child(new_dialog)
	new_dialog.connect("dialogic_signal", hud, "_on_intro_dialogic_signal")
	yield(new_dialog, "timeline_end")
	new_dialog.disconnect("dialogic_signal", hud, "_on_intro_dialogic_signal")
	new_dialog.queue_free()
	self.state = WorldState.START

func cutscene_eject():
	self.state = WorldState.CUTSCENE
	$MagicGirl.state = $MagicGirl.MagGirlState.IDLE
	var new_dialog = Dialogic.start($MagicGirl.girl_mode + " Eject")
	add_child(new_dialog)
	yield(new_dialog, "timeline_end")
	$MagicGirl.fly_out()
	new_dialog.queue_free()
	self.state = WorldState.START

func cutscene_pester():
	self.state = WorldState.CUTSCENE
	hud.gf_timer.paused = false
	$MagicGirl.state = $MagicGirl.MagGirlState.IDLE
	var new_dialog_name = $MagicGirl.get_next_pester_dialogue_name()
	var new_dialog = Dialogic.start(new_dialog_name)
	add_child(new_dialog)
	yield(new_dialog, "timeline_end")
	$MagicGirl.fly_out()
	new_dialog.queue_free()
	self.state = WorldState.ACTIVE

func cutscene_fail():
	self.state = WorldState.CUTSCENE
	$MagicGirl.fly_out()
	var new_dialog = Dialogic.start("Fail")
	add_child(new_dialog)
	yield(new_dialog, "timeline_end")
	new_dialog.queue_free()
	self.state = WorldState.FAIL

func cutscene_ending():
	self.state = WorldState.CUTSCENE
	$MagicGirl.fly_out()
	var new_dialog = Dialogic.start("Ending")
	add_child(new_dialog)
	yield(new_dialog, "timeline_end")
	new_dialog.queue_free()
	self.state = WorldState.END

func _on_NextPatrol_timeout():
	var girl = ""
	if randf() > 0.5:
		girl = "Micah"
	else:
		girl = "Rafa"
	$NextPatrol.stop()
	$MagicGirl.global_transform.origin = Vector3(-3, 10, $Player.global_transform.origin.z) 
	$MagicGirl.home_pos = Vector3(-3, 10, $Player.global_transform.origin.z)
	$MagicGirl.fly_in(Vector3(-3, 2, $Player.global_transform.origin.z), 15, 10, girl)

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

func _on_Player_shop_entered(shop):
	self.state = WorldState.CUTSCENE

func _on_Player_shop_exited(shop):
	self.state = WorldState.ACTIVE
