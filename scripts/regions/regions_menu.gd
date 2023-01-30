extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var region_menu = Core.get_subfile("PNG", "UI_IMAGE", 339829511)
	self.texture = region_menu.get_as_texture()
	self.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



