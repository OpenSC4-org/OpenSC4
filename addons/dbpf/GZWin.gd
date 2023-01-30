extends Control 
class_name GZWin

# Base class for the GUI reimplementation of SC4

func _init(attributes : Dictionary):
	var area = attributes.get('area', Rect2())
	self.visible = attributes.get('winflag_visible', true)
	self.set_position(area.position)
	self.set_size(area.size)
	if 'tipstext' in attributes:
		self.hint_tooltip = attributes.get('hint_tooltip')
