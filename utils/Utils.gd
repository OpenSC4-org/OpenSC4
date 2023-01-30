extends Node


func build_menu_icon(button, size : Vector2, instance_id : int):
	var btn_img = Core.get_subfile("PNG", "MENU_ICONS", instance_id)
	button.texture_disabled = AtlasTexture.new()
	button.texture_disabled.atlas = btn_img.get_as_texture()
	button.texture_disabled.region = Rect2(0, 0, size.x , size.y)
	
	button.texture_normal = AtlasTexture.new()
	button.texture_normal.atlas = btn_img.get_as_texture()
	button.texture_normal.region = Rect2(size.x, 0, size.x ,size.y)
	
	button.texture_pressed = AtlasTexture.new()
	button.texture_pressed.atlas = btn_img.get_as_texture()
	button.texture_pressed.region = Rect2(size.x*2, 0, size.x ,size.y)
	
	button.texture_hover = AtlasTexture.new()
	button.texture_hover.atlas = btn_img.get_as_texture()
	button.texture_hover.region = Rect2(size.x*3, 0, size.x ,size.y)

func build_check_button(active_btn, inactive_btn, size : Vector2, instance_id : int):
	var btn_img = Core.get_subfile("PNG", "UI_IMAGE", instance_id)
	active_btn.texture_disabled = AtlasTexture.new()
	active_btn.texture_disabled.atlas = btn_img.get_as_texture()
	active_btn.texture_disabled.region = Rect2(size.x*6, 0, size.x , size.y)
	
	active_btn.texture_normal = AtlasTexture.new()
	active_btn.texture_normal.atlas = btn_img.get_as_texture()
	active_btn.texture_normal.region = Rect2(0, 0, size.x ,size.y)
	
	active_btn.texture_pressed = AtlasTexture.new()
	active_btn.texture_pressed.atlas = btn_img.get_as_texture()
	active_btn.texture_pressed.region = Rect2(size.x*4, 0, size.x ,size.y)
	
	active_btn.texture_hover = AtlasTexture.new()
	active_btn.texture_hover.atlas = btn_img.get_as_texture()
	active_btn.texture_hover.region = Rect2(size.x*2, 0, size.x ,size.y)
	
	
	inactive_btn.texture_disabled = AtlasTexture.new()
	inactive_btn.texture_disabled.atlas = btn_img.get_as_texture()
	inactive_btn.texture_disabled.region = Rect2(size.x*7, 0, size.x , size.y)
	
	inactive_btn.texture_normal = AtlasTexture.new()
	inactive_btn.texture_normal.atlas = btn_img.get_as_texture()
	inactive_btn.texture_normal.region = Rect2(size.x, 0, size.x ,size.y)
	
	inactive_btn.texture_pressed = AtlasTexture.new()
	inactive_btn.texture_pressed.atlas = btn_img.get_as_texture()
	inactive_btn.texture_pressed.region = Rect2(size.x*5, 0, size.x ,size.y)
	
	inactive_btn.texture_hover = AtlasTexture.new()
	inactive_btn.texture_hover.atlas = btn_img.get_as_texture()
	inactive_btn.texture_hover.region = Rect2(size.x*3, 0, size.x ,size.y)
	

func build_button(button, size : Vector2, instance_id : int):
	var btn_img = Core.get_subfile("PNG", "UI_IMAGE", instance_id)
	button.texture_disabled = AtlasTexture.new()
	button.texture_disabled.atlas = btn_img.get_as_texture()
	button.texture_disabled.region = Rect2(0, 0, size.x , size.y)
	
	button.texture_normal = AtlasTexture.new()
	button.texture_normal.atlas = btn_img.get_as_texture()
	button.texture_normal.region = Rect2(size.x, 0, size.x ,size.y)
	
	button.texture_pressed = AtlasTexture.new()
	button.texture_pressed.atlas = btn_img.get_as_texture()
	button.texture_pressed.region = Rect2(size.x*2, 0, size.x ,size.y)
	
	button.texture_hover = AtlasTexture.new()
	button.texture_hover.atlas = btn_img.get_as_texture()
	button.texture_hover.region = Rect2(size.x*3, 0, size.x ,size.y)
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func translate_CUR_type_to_number(type):
	var types = {
		"normal":1,
		"point":17,
		"residential_2":23875110,
		"white_left_top_arrow":44463761,
		"landfill":48510238,
		"residential_3":48510244,
		"fire":48510263,
		"two_green_arrows":119428862,
		"green_arrow_down":119428863,
		"green_arrow_up":119428864,
		"white_arrow_to_sides":119428867,
		"terrain_down":119428868,
		"terrain_up":119428869,
		"red_dot":168346958,
		"yellow_arrow_down":177337795,
		"monorail":201611083,
		"cursor":330381520,
		"rail":561754888,
		"white_right_down_arrow":581334688,
		"industrial_3":585381138,
		"red_arrow_up":700884416,
		"orange_arrow_up":700884417,
		"hill_up":713831040,
		"simple_road":714214393,
		"sign":732711280,
		"green_arrow":1098834795,
		"dezone":1122252023,
		"industrial_1":1122252055,
		"red_dot_2":1242088830,
		"white_tree":1242770458,
		"caption":1265827394,
		"change_label":1265827586,
		"white_arrow_up":1655076358,
		"white_arrow_left":1655076500,
		"white_arrow_down":1655076507,
		"residential_1":1659122987,
		"anchor":1659122993,
		"tree":1725629823,
		"hill_down":1787572721,
		"caption_arrow":1802698447,
		"avenue":1802701699,
		"highway":1809879476,
		"question":2171436916,
		"white_arrow_right_top":2191947432,
		"pipe":2193817417,
		"comercial_1":2195993868,		
		"yellow_arrow_to_sides":2324822590,
		"elevated_highway":2347960971,
		"comercial_2":2708229674,
		"white_arrrow_left_down":2728818328,
		"yellow_arrow_top":2837411008,
		"terrain_level":2861264957,
		"hand_point":2861695065,
		"elevated_rail":2876893025,
		"oneway":2883621288,
		"steering_wheel":2883639990,
		"gimbal":2886651511,
		"white_circle":3245100571,
		"industrial_2":3245100592,
		"tunnel":3246109481,
		"white_arrow_right":3265689252,
		"white_arrows":3265689260,
		"comerical_3":3269735685,
		"calmdown":3269735741,
		"question_path":3415038804,
		"road":3782980198,
		"change_label_with_arrow":3950182132,
		"rail2":3957363126
	}
	if types.has(type):
		return types[type]
	
	return 1 # which is type 1

func dir_contents(path, filter_extension=""):
	var dirs = []
	var files = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				dirs.append(file_name)
			else:
				if filter_extension:
					if file_name.ends_with(filter_extension):
						files.append(file_name)
				else:
					files.append(file_name)
			file_name = dir.get_next()
	else:
		Logger.error("An error occurred when trying to access the path.")
		return
	return {
		"dirs" : dirs,
		"files" : files
	}
