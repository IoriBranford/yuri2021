extends Control

export var girlfriend_time = 90.0
export var transformation_time = 2
export var revert_time = 10
export var revert_warning_timeleft = 2.5
export var transformation_start_color = Color.aqua
export var transformation_finish_color = Color.bisque
export var revert_warning_color = Color.red

signal transformation_finished
signal transformation_canceled
signal transformation_timeout
signal girlfriend_timeout

# Accessor vars
onready var portraits = $Portraits
onready var player_timer = $MyTransformationTimer
onready var player_clock = $PlayerHUD/MyTransformationClock
onready var player_face = $PlayerHUD/MyPortrait
onready var gf_timer = $GirlfriendTimer
onready var gf_clock = $GirlfriendHUD/GirlfriendClock
onready var gf_face = $GirlfriendHUD/GirlfriendPortrait

func _ready():
	player_clock.max_value = revert_time
	player_clock.progress = 0
	gf_clock.max_value = girlfriend_time
	gf_clock.progress = girlfriend_time
	gf_timer.start(girlfriend_time)

func _physics_process(delta):
	var mtc_progress = player_clock.progress
	var mtc_max = player_clock.max_value
	if player_timer.is_stopped():
		var mtc_delta = mtc_max * delta / transformation_time
		if Input.is_action_pressed("player_transform"):
			mtc_progress = move_toward(mtc_progress, mtc_max, mtc_delta)
			if mtc_progress >= mtc_max:
				emit_signal("transformation_finished")
				player_face.texture = portraits.get_resource("player_human_normal")
				player_timer.start(revert_time)
		else:
			mtc_progress = move_toward(mtc_progress, 0, mtc_delta)
		player_clock.progress = mtc_progress
		player_clock.bar_color = lerp(transformation_start_color, transformation_finish_color, mtc_progress/mtc_max)
	else:
		if Input.is_action_just_pressed("player_transform"):
			emit_signal("transformation_canceled")
			_on_cancel_transformation()
		else:
			var mtt_timeleft = player_timer.time_left
			player_clock.progress = mtt_timeleft
			if mtt_timeleft <= revert_warning_timeleft:
				player_clock.bar_color = lerp(transformation_start_color, revert_warning_color, (1 + sin(6*PI*mtt_timeleft)) / 2)
	gf_clock.progress = gf_timer.time_left
	var timer_pct = gf_timer.time_left / girlfriend_time
	if timer_pct >= 0.75:
		gf_face.texture = portraits.get_resource("gf_normal")
	elif timer_pct >= 0.5:
		gf_face.texture = portraits.get_resource("gf_wait")
	elif timer_pct >= 0.25:
		gf_face.texture = portraits.get_resource("gf_worry")
	else:
		gf_face.texture = portraits.get_resource("gf_mad")

func _on_game_start():
	gf_timer.start(girlfriend_time)

func _on_cancel_transformation():
	player_timer.stop()
	player_clock.progress = 0
	player_face.texture = portraits.get_resource("player_kaiju_normal")

func _on_GirlfriendTimer_timeout():
	emit_signal("girlfriend_timeout")

func _on_MyTransformationTimer_timeout():
	emit_signal("transformation_timeout")
	_on_cancel_transformation()
