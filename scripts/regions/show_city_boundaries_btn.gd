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
	Utils.build_check_button(active_btn, inactive_btn, Vector2(17,17), 339829525)
	if Core.show_city_boundaries:
		self.set_button(active_btn)
	else:
		self.set_button(inactive_btn)

func _on_show_city_boundaries_btn_pressed():
	if Core.show_city_boundaries:
		self.set_button(inactive_btn)
		Core.show_city_boundaries = false
	else:
		self.set_button(active_btn)
		Core.show_city_boundaries = true
