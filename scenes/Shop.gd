extends Area

func _process(delta):
	$Inside/Sprite3D.rotate_y(delta*PI)

func _on_Player_got_item(shopname):
	if name == shopname:
		var newicon = $ResourcePreloader.get_resource(shopname+"_visited")
		$Inside/Sprite3D.texture = newicon
