extends GZWin
class_name GZWinText

var text : String 
var font = null

func _init(attributes).(attributes):
	# hack to get the default font while we can't decode the Simcity 4 ones
	var label = Label.new()
	self.font = label.get_font("")
	label.free()
	self.set_text(attributes.get('caption', ''))

func set_text(text : String):
	self.text = text
	self.update()

func _draw():
	draw_string(font, Vector2(0, font.get_height()), self.text, Color.white)

