extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var top_menu_image = Core.get_subfile("PNG", "UI_IMAGE", 339829519)
	self.texture = top_menu_image.get_as_texture()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
