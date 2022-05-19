extends TextureButton
class_name SC4Button 

# Texture order:
# 0. disabled
# 1. normal
# 2. pressed
# 3. hover 

func get_cropped_texture(texture, region):
	var atlas_texture = AtlasTexture.new()
	atlas_texture.set_atlas(texture)
	atlas_texture.set_region(region)
	return atlas_texture

func set_texture(main_texture):
	var width = main_texture.get_width() / 4
	var height = main_texture.get_height()
	self.texture_disabled = get_cropped_texture(main_texture, Rect2(0, 0, width, height))
	self.texture_normal = get_cropped_texture(main_texture, Rect2(width, 0, width, height))
	self.texture_pressed =  get_cropped_texture(main_texture, Rect2(2*width, 0, width, height))
	self.texture_hover = get_cropped_texture(main_texture, Rect2(3*width, 0, width, height))

