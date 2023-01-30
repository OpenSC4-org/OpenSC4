extends TextureRect

func _ready():
	var bottom_left_menu_img = Core.get_subfile("PNG", "UI_IMAGE", 339829504)
	self.texture = bottom_left_menu_img.get_as_texture()
