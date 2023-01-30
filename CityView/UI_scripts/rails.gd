extends TextureButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Utils.build_menu_icon(self, Vector2(44,44), 708761450)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_rails_pressed():
	Player.current_type_selected = "Rail"
	Player.set_cursor("rail")
