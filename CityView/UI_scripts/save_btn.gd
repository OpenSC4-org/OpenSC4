extends TextureButton

func _ready():
	Utils.build_button(self, Vector2(40,36), 333533105)


func _on_save_btn_pressed():
	Logger.warn("Save button - not yet implemented.")
