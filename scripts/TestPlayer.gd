extends KinematicBody

export var speed = 2.0

signal got_item(item)

var current_physics_process = funcref(self, "_physics_process_input")
var co_state = null
var nearby_shop:Area = null
var visited_shops = {
	Salon = false,
	GiftShop = false,
	RecordShop = false
}
onready var visited_fx = {
	Salon = $oceankaiju_human_form/SalonSparkle,
	GiftShop = $oceankaiju_human_form/Chocolatebox,
	RecordShop = $oceankaiju_human_form/MusicNotes
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
	for fx in visited_fx:
		visited_fx[fx].visible = false

func _physics_process_input(delta):
	var movement_x = Input.get_axis("player_left", "player_right")
	var movement = Vector3(movement_x, 0, 0)
	move_and_slide(speed * movement, Vector3.UP)
	if movement_x != 0:
		$oceankaiju_human_form.look_at(translation + movement, Vector3.UP)
	var scaley
	if Input.is_action_pressed("player_hide"):
		scaley = move_toward(scale.y, .5, delta*4)
	else:
		scaley = move_toward(scale.y, 1, delta*4)
	scale.y = scaley
	if Input.is_action_just_pressed("player_enter"):
		visit_shop()

func co_visit_shop():
	var delta
	var x = translation.x
	var shopx = nearby_shop.translation.x
		
	while x != shopx:
		$oceankaiju_human_form.look_at(translation + Vector3(shopx-x, 0, 0), Vector3.UP)
		delta = yield()
		x = move_toward(x, shopx, delta*speed)
		translation.x = x
		
	var mask = collision_mask
	collision_mask = 0

	$AnimationPlayer.play("enter_shop")
	yield(get_tree(), "idle_frame")
	yield($AnimationPlayer, "animation_finished")

	var shopname = nearby_shop.name
	var dialogue = Dialogic.start(shopname)
	if dialogue:
		get_tree().root.add_child(dialogue)
		yield(dialogue, "timeline_end")
	var fx = visited_fx[shopname]
	if fx:
		fx.visible = true
	visited_shops[shopname] = true
	emit_signal("got_item", shopname)

	$AnimationPlayer.play("exit_shop")
	yield(get_tree(), "idle_frame")
	yield($AnimationPlayer, "animation_finished")

	current_physics_process = funcref(self, "_physics_process_input")
	collision_mask = mask
	
func _physics_process_coroutine(delta):
	if co_state is GDScriptFunctionState && co_state.is_valid():
		co_state = co_state.resume(delta)
	else:
		co_state = null

func visit_shop():
	if nearby_shop and not visited_shops.get(nearby_shop.name, false):
		co_state = co_visit_shop()
		current_physics_process = funcref(self, "_physics_process_coroutine")

func _physics_process(delta):
	current_physics_process.call_func(delta)

func _on_shoparea_body_entered(body, shop):
	if self == body and !visited_shops[shop.name]:
		nearby_shop = shop

func _on_shoparea_body_exited(body, shop):
	if self == body and shop == nearby_shop:
		nearby_shop = null
