extends Control

export var girlfriend_time = 90
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

func _ready():
	$MyTransformationClock.max_value = revert_time
	$MyTransformationClock.progress = 0
	$GirlfriendClock.max_value = girlfriend_time
	$GirlfriendClock.progress = girlfriend_time
	$GirlfriendTimer.start(girlfriend_time)

func _physics_process(delta):
	var mtc_progress = $MyTransformationClock.progress
	var mtc_max = $MyTransformationClock.max_value
	if $MyTransformationTimer.is_stopped():
		var mtc_delta = mtc_max * delta / transformation_time
		if Input.is_action_pressed("player_transform"):
			mtc_progress = move_toward(mtc_progress, mtc_max, mtc_delta)
			if mtc_progress >= mtc_max:
				emit_signal("transformation_finished")
				$MyTransformationTimer.start(revert_time)
		else:
			mtc_progress = move_toward(mtc_progress, 0, mtc_delta)
		$MyTransformationClock.progress = mtc_progress
		$MyTransformationClock.bar_color = lerp(transformation_start_color, transformation_finish_color, mtc_progress/mtc_max)
	else:
		if Input.is_action_just_pressed("player_transform"):
			emit_signal("transformation_canceled")
			_on_cancel_transformation()
		else:
			var mtt_timeleft = $MyTransformationTimer.time_left
			$MyTransformationClock.progress = mtt_timeleft
			if mtt_timeleft <= revert_warning_timeleft:
				$MyTransformationClock.bar_color = lerp(transformation_start_color, revert_warning_color, (1 + sin(6*PI*mtt_timeleft)) / 2)

	$GirlfriendClock.progress = $GirlfriendTimer.time_left

func _on_game_start():
	$GirlfriendTimer.start(girlfriend_time)

func _on_cancel_transformation():
	$MyTransformationTimer.stop()
	$MyTransformationClock.progress = 0

func _on_GirlfriendTimer_timeout():
	emit_signal("girlfriend_timeout")

func _on_MyTransformationTimer_timeout():
	emit_signal("transformation_timeout")
	_on_cancel_transformation()
