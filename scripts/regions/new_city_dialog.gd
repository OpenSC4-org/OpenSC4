extends TextureRect

var city = null

func _ready():
	var bottom_left_menu_img = Core.get_subfile("PNG", "UI_IMAGE", 339829537)
	self.texture = bottom_left_menu_img.get_as_texture()

func set_city_to_dialog(city_info):
	self.city = city_info


func _on_play_city_btn_pressed():
	if self.city:
		self.city.open_city()
