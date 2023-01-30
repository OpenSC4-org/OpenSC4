extends TextureButton

func _ready():
		Utils.build_button(self, Vector2(40,36), 333533088)

func _on_exit_btn_pressed():
	self.get_tree().quit()
