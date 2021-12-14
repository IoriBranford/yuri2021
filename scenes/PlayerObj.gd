extends KinematicBody

export var MOVE_SPEED = 3
export var KNOCK_TIME = 1
export var TRANSFORM_CHARGE_TIME = 2
export var TRANSFORM_REVERT_TIME = 10
export var FOOTSTEP_SPEED = 0.6
export var GRAVITY = 8

signal transformation_updated
signal shop_nearby
signal no_shop_nearby
signal footstep(is_kaiju)

const COLL_KAIJU = {"translate":Vector3(0, 1.75, 0), "radius":1, "height":1.5}
const COLL_HUMAN = {"translate":Vector3(0, 0.875, 0), "radius":0.75, "height":0.25}

const SHOPS_WITH_EXIT_DIALOGUE = {
	"GiftShop": true
}

onready var knock_timer = $Knockback
onready var collision = $PlayerCollision

var obj_melee = preload("res://scenes/MeleeAttack.tscn")
var velocity = Vector3.ZERO
var in_knockback = false
var is_transformed = false
var transform_charge = 0 # to 1
var at_salon = false
var at_gift = false
var at_record = false
var footstep_timer = 0
var in_water = false

func smooth_look_at(target, up):
	var quat = Quat(transform.basis)
	var destquat = Quat(transform.looking_at(target, up).basis)
	quat = quat.slerp(destquat, 0.5)
	transform.basis = Basis(quat)

func move_player(delta):
	var move_dir = Vector3.ZERO
	if in_knockback:
		move_dir = Vector3.BACK
	else:
		move_dir = Vector3(
			Input.get_axis("ui_up", "ui_down"),
			0,
			Input.get_axis("ui_right", "ui_left"))
		if Input.is_action_just_pressed("player_attack"):
			if nearby_shop && visit_shop(nearby_shop):
				move_dir = Vector3.ZERO
			else:
				melee_attack()

	if is_transformed:
		if Input.is_action_just_pressed("player_transform"):
			transform_charge = 0
		else:
			transform_charge = move_toward(transform_charge, 0, delta/TRANSFORM_REVERT_TIME)
		if transform_charge <= 0:
			change_form()
	else:
		if !in_knockback && Input.is_action_pressed("player_transform"):
			transform_charge = move_toward(transform_charge, 1, delta/TRANSFORM_CHARGE_TIME)
			if transform_charge >= 1:
				change_form()
		else:
			transform_charge = move_toward(transform_charge, 0, delta/TRANSFORM_CHARGE_TIME)
	emit_signal("transformation_updated", is_transformed, transform_charge)

	if move_dir != Vector3.ZERO:
		smooth_look_at(global_transform.origin + move_dir.normalized(), Vector3.UP)
		sfx_footstep(delta)

	move_dir = move_dir.normalized() * MOVE_SPEED
	velocity.x = move_dir.x
	velocity.z = move_dir.z

	velocity.y -= delta*GRAVITY
	velocity = move_and_slide(velocity, Vector3.UP)

func melee_attack():
	var inst_melee = obj_melee.instance()
	add_child(inst_melee)
	inst_melee.translation = Vector3(0, 1, -3)
	$PlayerSFX/Attack.post_event()

func change_form():
	is_transformed = !is_transformed
	$SmokePuff.emitting = true
	$HumanForm.visible = is_transformed
	$KaijuForm.visible = !is_transformed
	if is_transformed:
		collision.translation = COLL_HUMAN.translate
		collision.shape.radius = COLL_HUMAN.radius
		collision.shape.height = COLL_HUMAN.height
		$PlayerSFX/Transform.post_event()
	else:
		collision.translation = COLL_KAIJU.translate
		collision.shape.radius = COLL_KAIJU.radius
		collision.shape.height = COLL_KAIJU.height
		$PlayerSFX/Revert.post_event()
	if nearby_shop:
		emit_signal("shop_nearby", nearby_shop.name, visited_shops[nearby_shop.name], is_transformed)

func knockback():
	in_knockback = true
	knock_timer.start(KNOCK_TIME)

func _on_Knockback_timeout():
	in_knockback = false
	knock_timer.stop()

signal shop_entered(shop_trigger)
signal shop_exited(shop_trigger)
signal got_item(item)

var co_state = null
var nearby_shop:Area = null
var visited_shops = {
	Salon = false,
	GiftShop = false,
	RecordShop = false
}
onready var visited_fx_human = {
	Salon = $HumanForm/SalonSparkle,
	GiftShop = $HumanForm/Chocolatebox,
	RecordShop = $HumanForm/MusicNotes
}
onready var visited_fx_kaiju = {
	Salon = $KaijuForm/SalonSparkle,
	GiftShop = $KaijuForm/Chocolatebox,
	RecordShop = $KaijuForm/MusicNotes
}

func connect_to_shop(nodepath:NodePath):
	var shop_trigger:Area = get_node(nodepath) as Area
	if shop_trigger:
		shop_trigger.connect("body_entered", self, "_on_shoparea_body_entered", [shop_trigger], 0)
		shop_trigger.connect("body_exited", self, "_on_shoparea_body_exited", [shop_trigger], 0)

func _ready():
	connect_to_shop("../Salon")
	connect_to_shop("../GiftShop")
	connect_to_shop("../RecordShop")
	for fx in visited_fx_human:
		visited_fx_human[fx].visible = false
	for fx in visited_fx_kaiju:
		visited_fx_kaiju[fx].visible = false

func walk_toward(dest, delta):
	smooth_look_at(dest, Vector3.UP)
	translation = translation.move_toward(dest, delta*MOVE_SPEED)

func co_visit_shop(shop_trigger:Spatial):
	var layer = collision_layer
	var mask = collision_mask
	collision_layer = 0
	collision_mask = 0

	var dest
	dest = shop_trigger.global_transform.origin
	dest.y = global_transform.origin.y
	while !translation.is_equal_approx(dest):
		yield(get_tree(), "physics_frame")
		walk_toward(dest, get_physics_process_delta_time())

	var inside = shop_trigger.get_node_or_null("Inside")
	if inside:
		inside = inside.global_transform.origin
	else:
		inside = shop_trigger.global_transform.origin
		inside.x -= 2
	dest = inside
	dest.y = global_transform.origin.y
	while !translation.is_equal_approx(dest):
		yield(get_tree(), "physics_frame")
		walk_toward(dest, get_physics_process_delta_time())

	var shopname = shop_trigger.name
	var dialogue = Dialogic.start(shopname)
	if dialogue:
		get_tree().root.add_child(dialogue)
		yield(dialogue, "timeline_end")

	var fx = visited_fx_human[shopname]
	if fx:
		fx.visible = true
	fx = visited_fx_kaiju[shopname]
	if fx:
		fx.visible = true
	visited_shops[shopname] = true
	emit_signal("got_item", shopname)

	dest = shop_trigger.global_transform.origin
	dest.y = global_transform.origin.y
	while !translation.is_equal_approx(dest):
		yield(get_tree(), "physics_frame")
		walk_toward(dest, get_physics_process_delta_time())

	if SHOPS_WITH_EXIT_DIALOGUE.has(shopname):
		dialogue = Dialogic.start("%s Exit" % shopname)
		if dialogue:
			get_tree().root.add_child(dialogue)
			yield(dialogue, "timeline_end")
		
	collision_layer = layer
	collision_mask = mask
	emit_signal("shop_exited", shop_trigger)

func visit_shop(shop_trigger):
	if is_transformed and !in_knockback:
		if !visited_shops[shop_trigger.name]:
			co_state = co_visit_shop(shop_trigger)
			emit_signal("shop_entered", shop_trigger)
			return true
	return false
	
func _on_shoparea_body_entered(body, shop_trigger):
	if self == body:
		nearby_shop = shop_trigger
		emit_signal("shop_nearby", shop_trigger.name, visited_shops[shop_trigger.name], is_transformed)

func _on_shoparea_body_exited(body, shop_trigger):
	if self == body:
		if shop_trigger == nearby_shop:
			nearby_shop = null
			emit_signal("no_shop_nearby")

func _on_Water_body_entered(body):
	if self == body:
		in_water = true

func _on_Water_body_exited(body):
	if self == body:
		in_water = false

func sfx_footstep(delta):
	if footstep_timer > FOOTSTEP_SPEED:
		emit_signal("footstep", !is_transformed)
		if in_water:
			$PlayerSFX/WaterFootstep.post_event()
		else:
			$PlayerSFX/Footstep.post_event()
			$KaijuForm/FootstepDust.emitting = true
			$KaijuForm/FootstepDust.restart()
		footstep_timer = 0
	footstep_timer += delta
