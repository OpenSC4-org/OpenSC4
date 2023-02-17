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
	if attributes.has('captionres'):
		# Read hex reference
		# The format is as follows: 0x{group_id,instance_id}
		Logger.info("Captionres value: %s" % attributes['captionres'])
		var captionres = attributes['captionres'].trim_prefix('{').trim_suffix('}').split(',')
		var group_id = ("0x%s"%captionres[0]).hex_to_int()
		var instance_id = ("0x%s"%captionres[1]).hex_to_int()
		# Read string from subfile
		var ltext_subfile = Core.subfile(0x2026960B, group_id, instance_id, LTEXTSubfile)
		if ltext_subfile != null:
			self.set_text(ltext_subfile.text)
		else:
			self.set_text("%s || ERROR"%attributes.get('caption', 'no caption defined'))

func set_text(text : String):
	self.text = text
	self.update()

func _draw():
	draw_string(font, Vector2(0, font.get_height()), self.text, Color.white)

