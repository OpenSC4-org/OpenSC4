extends TextureButton

func _ready():
	var texture = load("res://images/button/buttons.png")
	var size = Vector2(140,30)
	
	self.texture_disabled = AtlasTexture.new()
	self.texture_disabled.atlas = texture
	self.texture_disabled.region = Rect2(0, 0, size.x , size.y)
	
	self.texture_normal = AtlasTexture.new()
	self.texture_normal.atlas = texture
	self.texture_normal.region = Rect2(size.x, 0, size.x ,size.y)
	
	self.texture_pressed = AtlasTexture.new()
	self.texture_pressed.atlas = texture
	self.texture_pressed.region = Rect2(size.x*2, 0, size.x ,size.y)
	
	self.texture_hover = AtlasTexture.new()
	self.texture_hover.atlas = texture
	self.texture_hover.region = Rect2(size.x*3, 0, size.x ,size.y)

func _on_cancel_btn_pressed():
	self.get_parent().visible = false
