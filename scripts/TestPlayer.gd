extends KinematicBody

export var speed = 2.0

func _ready():
	pass

func _process(delta):
	pass

func _physics_process(delta):
	var movement_x = Input.get_axis("player_left", "player_right")
	move_and_slide(speed * Vector3(movement_x, 0, 0), Vector3.UP)
	if Input.is_action_pressed("player_hide"):
		var scaley = move_toward(scale.y, .5, delta*4)
		scale.y = scaley
	else:
		var scaley = move_toward(scale.y, 1, delta*4)
		scale.y = scaley
