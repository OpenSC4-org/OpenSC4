extends Sprite

class_name RegionViewCityThumbnail

func _unhandled_input(event):
	if event is InputEventMouseButton and not event.is_echo() and event.button_index == BUTTON_LEFT:
		var local_pos = to_local(event.global_position)
		if get_rect().has_point(local_pos):
			print('Click at %d %d' % [local_pos.x, local_pos.y])
			print('Rect: %d %d %d %d' % [get_rect().position.x, get_rect().position.y, get_rect().size.x, get_rect().size.y])
			get_tree().set_input_as_handled()
