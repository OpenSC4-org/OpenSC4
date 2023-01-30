extends TileMap


var cities : Array = []
var width : int = 0
var height : int = 0

var last_city_hovered = null
var last_city_selected = null

func init_cities_array(width_, height_):
	self.width = width_
	self.height = height_
	for i in range(width_):
		cities.append([])
		for _j in range(height_):
			cities[i].append(null)

func clear_everything():
	last_city_hovered = null
	last_city_selected = null
	width = 0
	height = 0
	for city in cities:
		for place in city:
			if place:
				place.queue_free()

func _unhandled_input(event):

	if event is InputEventMouseButton and event.pressed:
		var grid_position : Vector2 = world_to_map(get_global_mouse_position())
		if grid_position.x >= 0 and grid_position.x < width and grid_position.y >= 0 and grid_position.y < height:
			var current_city_selected = cities[grid_position.x][grid_position.y]
			if last_city_selected != current_city_selected:
				if last_city_selected:
					last_city_selected.on_unselect()
				current_city_selected.on_select()
				last_city_selected = current_city_selected
			
			
	if event is InputEventMouse and event.position:
		var grid_position : Vector2 = world_to_map(get_global_mouse_position())
		if grid_position.x >= 0 and grid_position.x < width and grid_position.y >= 0 and grid_position.y < height:
			var current_city_hovered = cities[grid_position.x][grid_position.y]
			if last_city_hovered != current_city_hovered:
				if last_city_hovered:
					last_city_hovered.on_mouse_unhovered()
				current_city_hovered.on_mouse_hovered()
				last_city_hovered = current_city_hovered
			
			
		
