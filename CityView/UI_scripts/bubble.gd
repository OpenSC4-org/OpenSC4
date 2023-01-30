extends TextureRect


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	var bubble = Core.get_subfile("PNG", "UI_IMAGE", 337731282)
	self.texture = AtlasTexture.new()
	self.texture.atlas = bubble.get_as_texture()
	self.texture.region = Rect2(0,0,80,53)
	self.visible = false
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_rails_btn_pressed():
	self.visible = !self.visible
