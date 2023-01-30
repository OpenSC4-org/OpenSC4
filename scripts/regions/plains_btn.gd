extends TextureButton


var active_btn : TextureButton = null
var inactive_btn : TextureButton = null

var parent : Node = null

func set_button(btn):
	self.texture_disabled = btn.texture_disabled
	self.texture_normal = btn.texture_normal
	self.texture_pressed = btn.texture_pressed
	self.texture_hover = btn.texture_hover


func _ready():
	parent = self.get_parent()
	active_btn = TextureButton.new()
	inactive_btn = TextureButton.new()
	Utils.build_check_button(active_btn, inactive_btn, Vector2(17,17), 339829526)
	
	if parent.plain_or_water:
		self.set_button(active_btn)
	else:
		self.set_button(inactive_btn)


func _on_plains_btn_pressed():
	parent.plain_or_water = true
	self.set_button(active_btn)
	parent.get_child(7).set_button(inactive_btn)


func _on_water_btn_pressed():
	parent.plain_or_water = false
	self.set_button(inactive_btn)
	parent.get_child(7).set_button(active_btn)
