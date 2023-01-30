extends Control


var drag_position = null # null = not in dragging state

func _ready():
	var dialog_texture = Core.get_subfile("PNG", "UI_IMAGE", 339829230).get_as_texture()
	
	var left_side_dialog = self.get_child(0)
	left_side_dialog.texture = AtlasTexture.new()
	left_side_dialog.texture.atlas = dialog_texture
	left_side_dialog.texture.region = Rect2(0,0,20,180)
	
	var center_1 = self.get_child(1)
	center_1.texture = AtlasTexture.new()
	center_1.texture.atlas = dialog_texture
	center_1.texture.region = Rect2(20,0,160,180)
	
	var center_2 = self.get_child(2)
	center_2.texture = AtlasTexture.new()
	center_2.texture.atlas = dialog_texture
	center_2.texture.region = Rect2(20,0,160,180)

	self.visible = false



func _on_load_region_dialog_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# Start dragging
			drag_position = get_global_mouse_position() - rect_global_position
		else:
			# End dragging
			drag_position = null
	if event is InputEventMouseMotion and drag_position:
		rect_global_position = get_global_mouse_position() - drag_position


func _on_open_region_btn_pressed():
	self.visible = ! self.visible


func _on_new_region_btn_pressed():
	self.visible = false


func _on_cancel_btn_pressed():
	self.visible = false

