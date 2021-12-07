extends KinematicBody

export var MOVE_SPEED = 3
export var KNOCK_TIME = 1
export var TRANSFORM_CHARGE_TIME = 2
export var TRANSFORM_REVERT_TIME = 10

signal transformation_updated
signal shop_nearby
signal no_shop_nearby

const COLL_KAIJU = {"translate":Vector3(0, 1.75, 0), "radius":1, "height":1.5}
const COLL_HUMAN = {"translate":Vector3(0, 0.875, 0), "radius":0.75, "height":0.25}

onready var knock_timer = $Knockback
onready var collision = $PlayerCollision

var obj_melee = preload("res://scenes/MeleeAttack.tscn")
var move_dir = Vector3.ZERO
var in_knockback = false
var is_transformed = false
var transform_charge = 0 # to 1
var at_salon = false
var at_gift = false
var at_record = false

func smooth_look_at(target, up):
	var quat = Quat(transform.basis)
	var destquat = Quat(transform.looking_at(target, up).basis)
	quat = quat.slerp(destquat, 0.5)
	transform.basis = Basis(quat)

func move_player(delta):
	if in_knockback:
		move_dir = Vector3.BACK
	else:
		move_dir = Vector3(
			Input.get_axis("ui_up", "ui_down"),
			0,
			Input.get_axis("ui_right", "ui_left"))
		if Input.is_action_just_pressed("player_attack"):
			if nearby_shop:
				visit_shop(nearby_shop)
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
		move_dir = move_dir.normalized() * MOVE_SPEED
		move_and_slide(move_dir, Vector3.UP)

func melee_attack():
	var inst_melee = obj_melee.instance()
	add_child(inst_melee)
	inst_melee.translation = Vector3(0, 1, -3)

func change_form():
	is_transformed = !is_transformed
	$SmokePuff.emitting = true
	$HumanForm.visible = is_transformed
	$KaijuForm.visible = !is_transformed
	if is_transformed:
		collision.translation = COLL_HUMAN.translate
		collision.shape.radius = COLL_HUMAN.radius
		collision.shape.height = COLL_HUMAN.height
	else:
		collision.translation = COLL_KAIJU.translate
		collision.shape.radius = COLL_KAIJU.radius
		collision.shape.height = COLL_KAIJU.height

func knockback():
	in_knockback = true
	knock_timer.start(KNOCK_TIME)

func _on_Knockback_timeout():
	in_knockback = false
	knock_timer.stop()

signal shop_entered(shop)
signal shop_exited(shop)
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
	var shop:Area = get_node(nodepath) as Area
	if shop:
		shop.connect("body_entered", self, "_on_shoparea_body_entered", [shop], 0)
		shop.connect("body_exited", self, "_on_shoparea_body_exited", [shop], 0)

func _ready():
	connect_to_shop("../Salon")
	connect_to_shop("../GiftShop")
	connect_to_shop("../RecordShop")
	for fx in visited_fx_human:
		visited_fx_human[fx].visible = false
	for fx in visited_fx_kaiju:
		visited_fx_kaiju[fx].visible = false

func co_visit_shop(shop):
	var mask = collision_mask
	collision_mask = 0

	var delta
	var z = translation.z
	var shopz = shop.translation.z
		
	while z != shopz:
		smooth_look_at(translation + Vector3(shopz-z, 0, 0), Vector3.UP)
		delta = yield()
		z = move_toward(z, shopz, delta*MOVE_SPEED)
		translation.z = z

	# $AnimationPlayer.play("enter_shop")
	# yield(get_tree(), "idle_frame")
	# yield($AnimationPlayer, "animation_finished")

	var shopname = shop.name
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

	# $AnimationPlayer.play("exit_shop")
	# yield(get_tree(), "idle_frame")
	# yield($AnimationPlayer, "animation_finished")

	collision_mask = mask
	emit_signal("shop_exited", shop)

func _physics_process(delta):
	if co_state is GDScriptFunctionState && co_state.is_valid():
		co_state = co_state.resume(delta)
	else:
		co_state = null

func visit_shop(shop):
	if is_transformed and !in_knockback:
		if !visited_shops[shop.name]:
			co_state = co_visit_shop(shop)
			emit_signal("shop_entered", shop)
	
func _on_shoparea_body_entered(body, shop):
	if self == body:
		nearby_shop = shop
		emit_signal("shop_nearby", shop.name, visited_shops[shop.name], is_transformed)

func _on_shoparea_body_exited(body, shop):
	if self == body:
		if shop == nearby_shop:
			nearby_shop = null
			emit_signal("no_shop_nearby")
