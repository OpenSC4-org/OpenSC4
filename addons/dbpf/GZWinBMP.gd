extends GZWin 
class_name GZWinBMP

var texture : Texture = null

func _init(attributes).(attributes):
	if not 'image' in attributes:
		print(attributes)
	else:
		set_texture(attributes['image'].get_as_texture())

func set_texture(texture : Texture):
	self.texture = texture
	update()

func _draw():
	if self.texture != null:
		draw_texture(texture, get_position())
