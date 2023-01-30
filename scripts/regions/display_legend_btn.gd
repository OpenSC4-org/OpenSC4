extends TextureButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Utils.build_button(self, Vector2(21,17), 1394886024)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_display_legend_btn_pressed():
	self.visible = false


func _on_minimalize_btn_pressed():
	self.visible = true
