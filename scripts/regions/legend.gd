extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var bottom_left_menu_img = Core.get_subfile("PNG", "UI_IMAGE", 1807644565)
	self.texture = bottom_left_menu_img.get_as_texture()
	self.visible = false


func _on_minimalize_btn_pressed():
	self.visible = false


func _on_display_legend_btn_pressed():
	self.visible = true
