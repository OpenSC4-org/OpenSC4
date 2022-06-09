extends TileMap


var cities : Array = []
var width : int = 0
var height : int = 0

func init_cities_array(width, height):
	self.width = width
	self.height = height
	for i in range(width):
		cities.append([])
		for j in range(height):
			cities[i].append(null)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.doubleclick:
		# Get the grid position
		var grid_position : Vector2 = world_to_map(get_global_mouse_position())
		if grid_position.x >= 0 and grid_position.x < width and grid_position.y >= 1 and grid_position.y < height:
			cities[grid_position.x][grid_position.y].open_city()
			
