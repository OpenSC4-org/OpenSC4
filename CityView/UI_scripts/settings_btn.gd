extends TextureButton

# Texture for this button is scaled (0.66) 
# therefore "settings_menu" cannot be its 
# child like it is in case of building_menu_btn
# otherwise it would be also scaled down

func _ready():
	Utils.build_button(self, Vector2(60,46), 339829508)
