extends TextureButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


	
# Called when the node enters the scene tree for the first time.
func _ready():
	Utils.build_button(self, Vector2(60,46), 339829508)
	
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_settings_pressed():
	self.get_child(0).visible = !self.get_child(0).visible


func _on_regions_btn_pressed():
	self.get_child(0).visible = false
	self.pressed = false
