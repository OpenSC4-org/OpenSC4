extends GZWin
class_name GZWinFlatRect

var color : Color = Color(1, 1, 1)

var nofill = false

func _init(attributes : Dictionary):
	print(attributes)
	if attributes.get("style", "") == "nofill":
		nofill = true
	queue_redraw()

func _draw():
	pass
	#TODO: should be capable of drawing each border with a different color
	if false:
		draw_rect(Rect2(Vector2(), self.get_size()), color, not nofill)
