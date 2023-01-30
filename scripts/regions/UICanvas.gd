extends CanvasLayer

var snapshot_window : TextureRect = null

func _ready():
	self.snapshot_window = self.get_node("screenshot_rect")

func _unhandled_input(event):
	if event is InputEventKey and event.scancode == KEY_F12:
		if event.pressed:			
			self.snapshot_window.visible = not self.snapshot_window.visible
