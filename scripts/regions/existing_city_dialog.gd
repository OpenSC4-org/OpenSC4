extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var city = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var bottom_left_menu_img = Core.get_subfile("PNG", "UI_IMAGE", 339829538)
	self.texture = bottom_left_menu_img.get_as_texture()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func set_city_to_dialog(city_info):
	self.city = city_info

	
	

func _on_play_city_btn_pressed():
	if self.city:
		self.city.open_city()
