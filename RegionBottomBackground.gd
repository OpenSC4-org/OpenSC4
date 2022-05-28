tool
extends TextureRect

export (Resource) var resource setget set_texture

func set_texture(res, value):
	resource = res 
	self.texture = resource.ui_region_textures[value]
