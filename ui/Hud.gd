extends Control

export var girlfriend_time = 90.0
export var revert_warning_percent = .25
export var transformation_start_color = Color.aqua
export var transformation_finish_color = Color.bisque
export var revert_warning_color = Color.red
export var item_default_env:Environment = load("res://default_env.tres")
export var item_missing_env:Environment = load("res://ui/env_item_dont_have.tres")

signal girlfriend_timeout

# Accessor vars
onready var portraits = $Portraits
onready var player_clock = $PlayerHUD/MyTransformationClock
onready var player_face = $PlayerHUD/MyPortrait
onready var gf_timer = $GirlfriendTimer
onready var gf_clock = $GirlfriendHUD/GirlfriendClock
onready var gf_face = $GirlfriendHUD/GirlfriendPortrait

onready var inv_gift = $InventoryHUD/Gift
onready var inv_stylist = $InventoryHUD/Stylist
onready var inv_music = $InventoryHUD/Music
onready var inv_icons = {
	Salon = inv_stylist,
	GiftShop = inv_gift,
	RecordShop = inv_music
}

onready var alert_hud = $Alert
onready var alert_bar = $Alert/CenterContainer/AlertBar
onready var alert_red = $Alert/CenterContainer/AlertRed

func set_inv(inv:Control, has:bool):
	var viewport:Viewport = inv.get_node("Viewport")
	if viewport:
		if has:
			viewport.world.environment = item_default_env
		else:
			viewport.world.environment = item_missing_env
	
func _ready():
	gf_clock.max_value = girlfriend_time
	gf_clock.progress = girlfriend_time
	gf_timer.start(girlfriend_time)
	set_inv(inv_gift, false)
	set_inv(inv_stylist, false)
	set_inv(inv_music, false)

func _on_Player_transformation_updated(is_transformed, transform_charge):
	player_clock.progress = transform_charge
	if is_transformed:
		player_face.texture = portraits.get_resource("player_human_normal")
		if transform_charge <= revert_warning_percent:
			player_clock.bar_color = lerp(transformation_start_color, revert_warning_color, (1 + sin(15*PI*transform_charge)) / 2)
		else:
			player_clock.bar_color = transformation_finish_color
	else:
		player_face.texture = portraits.get_resource("player_kaiju_normal")
		player_clock.bar_color = lerp(transformation_start_color, transformation_finish_color, transform_charge)

func _physics_process(delta):
	# Update girlfriend timer and HUD element
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

# Update alert HUD element
func update_alert(mag_girl):
	match mag_girl.state:
		mag_girl.MagGirlState.IDLE:
			alert_hud.visible = false
		mag_girl.MagGirlState.FLY_IN:
			alert_hud.visible = true
			alert_bar.value = 0
			alert_red.visible = false
		mag_girl.MagGirlState.PATROL:
			alert_hud.visible = true
			alert_bar.value = 0
			alert_red.visible = false
		mag_girl.MagGirlState.SEARCH:
			alert_hud.visible = true
			alert_bar.value = mag_girl.alert
			alert_red.visible = false
		mag_girl.MagGirlState.ATTACK, mag_girl.MagGirlState.PESTER:
			alert_hud.visible = true
			alert_red.visible = true
		mag_girl.MagGirlState.FLY_OUT:
			alert_hud.visible = false

func _on_game_start():
	gf_timer.start(girlfriend_time)

func _on_GirlfriendTimer_timeout():
	emit_signal("girlfriend_timeout")

func _on_player_got_item(shopname):
	var icon = inv_icons[shopname]
	if icon:
		set_inv(icon, true)

func _on_Player_shop_nearby(shopname, visited, is_transformed):
	var stringformat = ""
	if visited:
		stringformat = "You've already been to the %s"
	elif is_transformed:
		stringformat = "Z key: Enter %s"
	else:
		stringformat = "You're too big to get into the %s\nHold Space key: transform"

	$ShopInstruction.visible = true
	$ShopInstruction.text = stringformat % shopname

func _on_Player_no_shop_nearby():
	$ShopInstruction.visible = false
