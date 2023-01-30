extends Node



var current_type_selected = "Road"


func _ready():
	pass # Replace with function body.


func set_cursor(type):
	var instance_id = Utils.translate_CUR_type_to_number(type)

	var cur = Core.get_subfile("unknown_type1", "CUR", instance_id)
	var hotspot_vector = cur.entries[0].vec_hotspot
	var cur_texture = cur.get_as_texture()

	Input.set_custom_mouse_cursor(cur_texture, Input.CURSOR_ARROW, hotspot_vector)

