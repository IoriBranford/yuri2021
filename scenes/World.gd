extends Spatial

enum WorldState {TITLE, START, ACTIVE, CUTSCENE, FAIL, END}

onready var hud = $Hud

export var bigfoot_shake_amplitude = .25

var menu_index = 0
var state = WorldState.TITLE setget set_state
var sound_on = true
var cam_shake = 0

func set_state(value):
	if state == WorldState.TITLE and value != WorldState.TITLE:
		$TitleScreen.visible = false
	match value:
		WorldState.TITLE:
			$TitleScreen.visible = true
			$CreditScreen.visible = false
			hud.gf_timer.paused = true
		WorldState.START:
			$NextPatrol.stop()
			hud.gf_timer.paused = false
		WorldState.CUTSCENE:
			$NextPatrol.stop()
			hud.gf_timer.paused = true
		WorldState.ACTIVE:
			$NextPatrol.start((randi() % 5) + 4)
			hud.gf_timer.paused = false
		WorldState.FAIL:
			$NextPatrol.stop()
			$Hud/BigMessage/Label.text = "DATE FAILED"
			$Hud/BigMessage/Label2.text = "Aw man, you blew it!\nPress attack (Z) to try again!"
			$Hud/BigMessage.visible = true
			$WinLoseSoundPlayer.stream = $WinLoseSoundPlayer/ResourcePreloader.get_resource("quest_fail")
			$WinLoseSoundPlayer.play()
		WorldState.END:
			$NextPatrol.stop()
			$Hud/BigMessage/Label.text = "DATE SUCCESSFUL"
			$Hud/BigMessage/Label2.text = "Hell yeah! You crushed it!\nPress attack (Z) to restart!"
			$Hud/BigMessage.visible = true
			hud.gf_timer.paused = true
			$WinLoseSoundPlayer.stream = $WinLoseSoundPlayer/ResourcePreloader.get_resource("quest_success")
			$WinLoseSoundPlayer.play()
	state = value

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$Hud.connect("girlfriend_timeout", self, "cutscene_fail")
	$Player.add_to_group("player")
	$Player.connect("shop_nearby", $Hud, "_on_Player_shop_nearby")
	$Player.connect("no_shop_nearby", $Hud, "_on_Player_no_shop_nearby")
	$MagicGirl.add_to_group("enemy")
	$MagicGirl.connect("patrol_done", self, "new_patrol")
	$MagicGirl.connect("update_hud", $Hud, "update_alert")
	$MagicGirl.connect("pester", self, "cutscene_pester")
	$BankDefault.load_bank()
	self.state = WorldState.TITLE

func _physics_process(delta):
	$CamBase.translation = $Player.translation
	cam_shake = max(0, cam_shake - delta)
	$CamBase.translation.y += cam_shake*cos(15*PI*OS.get_ticks_msec()/1000)
	match state:
		WorldState.TITLE:
			var menu_items = $TitleScreen/Main/Menu.get_children()
			var menu_sfx = $TitleScreen/Main/MenuSFX
			if Input.is_action_just_pressed("player_attack"):
				if $CreditScreen.visible:
					$CreditScreen.visible = false
				else:
					var menu_item = menu_items[menu_index]
					match menu_item.name:
						"Start":
							$TitleScreen.visible = false
							self.state = WorldState.START
							menu_sfx.get_node("Exit Menu").post_event()
							cutscene_intro()
						"Sound":
							sound_on = !sound_on
						"Credit":
							$CreditScreen.visible = true
						"Quit":
							get_tree().quit()
			if Input.is_action_just_pressed("ui_up"):
				menu_index -= 1
				menu_sfx.get_node("Scroll Menu").post_event()
			if Input.is_action_just_pressed("ui_down"):
				menu_index += 1
				menu_sfx.get_node("Scroll Menu").post_event()
			if menu_index >= menu_items.size():
				menu_index = menu_items.size() - 1 
			if menu_index < 0:
				menu_index = 0
			for i in menu_items.size():
				if i == menu_index:
					menu_items[menu_index].modulate = Color(0,1,0)
				else:
					menu_items[i].modulate = Color(1,1,1)
		WorldState.START, WorldState.ACTIVE:
			$Player.move_player(delta)
			$Player.crush_building_underfoot($GridMap)
		WorldState.CUTSCENE:
			pass
		WorldState.FAIL:
			if Input.is_action_just_pressed("player_attack"):
				if !$WinLoseSoundPlayer.playing:
					get_tree().reload_current_scene()
		WorldState.END:
			if Input.is_action_just_pressed("player_attack"):
				if !$WinLoseSoundPlayer.playing:
					get_tree().reload_current_scene()

func new_patrol():
	if state == WorldState.ACTIVE:
		$NextPatrol.start((randi() % 5) + 2)

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
	$NextPatrol.stop()
	var new_dialog = Dialogic.start("Fail")
	add_child(new_dialog)
	yield(new_dialog, "timeline_end")
	new_dialog.queue_free()
	self.state = WorldState.FAIL

func cutscene_ending():
	self.state = WorldState.CUTSCENE
	$MagicGirl.swat()
	$NextPatrol.stop()
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

func _on_Player_footstep(is_kaiju):
	if is_kaiju:
		cam_shake = bigfoot_shake_amplitude
