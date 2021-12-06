extends Spatial

const MOVE_SPEED = 5
var move_dir = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var from = global_transform.origin
	var to = from + move_dir
	global_transform.origin = from.move_toward(to, delta * MOVE_SPEED)

func set_color(color):
	$MeshInstance.material_override.albedo_color = color
	$FireParticle.draw_pass_1.material.albedo_color = color
	pass

func _on_Area_body_entered(body):
	if body.is_in_group("player"):
		body.knockback()
		queue_free()
