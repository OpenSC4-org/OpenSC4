extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var settings_menu = Core.get_subfile("PNG", "UI_IMAGE", 335631686)
	self.texture = settings_menu.get_as_texture()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_building_menu_btn_pressed():
	self.visible = ! self.visible


func _on_settings_btn_pressed():
	self.visible = false
