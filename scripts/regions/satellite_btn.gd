extends TextureButton

var active_btn : TextureButton = null
var inactive_btn : TextureButton = null

func set_button(btn):
	self.texture_disabled = btn.texture_disabled
	self.texture_normal = btn.texture_normal
	self.texture_pressed = btn.texture_pressed
	self.texture_hover = btn.texture_hover

func _ready():
	active_btn = TextureButton.new()
	inactive_btn = TextureButton.new()
	Utils.build_check_button(active_btn, inactive_btn, Vector2(17,17), 339829526)
	# Core.satellite_view - true = satellite View, false = Transportation Map
	if not Core.satellite_view:
		self.set_button(active_btn)
	else:
		self.set_button(inactive_btn)

func _on_transport_btn_pressed():
	Core.satellite_view = false
	self.set_button(inactive_btn)
	self.get_parent().get_child(6).set_button(active_btn)

func _on_satellite_btn_pressed():
	Core.satellite_view = true
	self.set_button(active_btn)
	self.get_parent().get_child(6).set_button(inactive_btn)	
