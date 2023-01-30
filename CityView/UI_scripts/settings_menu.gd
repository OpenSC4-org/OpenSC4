extends TextureRect

func _ready():
	var settings_menu = Core.get_subfile("PNG", "UI_IMAGE", 333533040)
	self.texture = settings_menu.get_as_texture()
	self.visible=false


func _on_settings_btn_pressed():
	self.visible = not self.visible


func _on_building_menu_btn_pressed():
	self.visible = false
