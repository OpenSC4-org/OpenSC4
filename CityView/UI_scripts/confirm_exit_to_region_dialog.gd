extends Control

var drag_position = null # null = not in dragging state

func _ready():
	self.visible = false


func _on_cancel_btn_pressed():
	self.visible = false


func _on_to_region_btn_pressed():
	self.visible = true


func _on_confirm_exit_to_region_dialog_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# Start dragging
			drag_position = get_global_mouse_position() - rect_global_position
		else:
			# End dragging
			drag_position = null
	if event is InputEventMouseMotion and drag_position:
		rect_global_position = get_global_mouse_position() - drag_position
