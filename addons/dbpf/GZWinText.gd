extends GZWin
class_name GZWinText

var text : String = ""

func _init(attributes).(attributes):
	self.text = attributes.get('caption', '')
