extends TextureRect


var drag_position = null # null = not in dragging state


func _ready():
	self.visible = false


func take_snapshot():
	self.get_child(0).visible = false
	var pos = self.rect_position
	var size = self.rect_size
	# The wait must be there otherwise the text won't disappear in time
	yield(get_tree().create_timer(0.1), "timeout")
	var viewport = get_viewport()
	var tex = viewport.get_texture()
	var y = 0	
	y = viewport.size.y - pos.y - size.y
	var image = tex.get_data().get_rect(Rect2(pos.x,y ,size.x,size.y))
	var timestamp = OS.get_ticks_msec() % 1000
	image.flip_y()
	# Check if directory with screenshots exists
	var check_directory = Directory.new()
	if not check_directory.dir_exists("user://screenshots"):
		check_directory.make_dir_recursive("user://screenshots")
	# Save the image
	image.save_png("user://screenshots/%s.png" % str(timestamp))
	self.get_child(0).visible = true


func _unhandled_input(event):
	if event is InputEventKey and event.scancode == KEY_ESCAPE:
		if event.pressed:
			self.visible = false
	if event is InputEventKey and event.scancode == KEY_C and self.visible:
		if event.pressed:
			self.take_snapshot()


func _on_screenshot_rect_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# Start dragging
			drag_position = get_global_mouse_position() - rect_global_position
		else:
			# End dragging
			drag_position = null
	if event is InputEventMouseMotion and drag_position:
		rect_global_position = get_global_mouse_position() - drag_position


func _on_screenshot_btn_pressed():
	# Signal from region - RegionView
	self.visible = true


func _on_snapshot_btn_pressed():
	# Signal from game - CityView
	self.visible = true
