extends "res://DBPFLoader.gd"

var region_view_thumbnails = []

# Size, in pixels, of the tile base

var TILE_BASE_HEIGHT = 18
var TILE_BASE_WIDTH = 90


func _init(filepath).(filepath):
	# Load the thumbnails
	# Note: should be 0, 2, 4, 6, but for some reason only 2 and 4 are ever present
	for instance_id in [0, 2]:
		region_view_thumbnails.append(self.get_subfile(0x8a2482b9, 0x4a2482bb, instance_id))

func _ready():
	display()

func display():
	# Get the regional city info
	var city_info = self.get_subfile(0xca027edb, 0xca027ee1, 0)
	var city_sprite = self.region_view_thumbnails[0].sprite
	var grid = $"../BaseGrid"
	var pos_on_grid = grid.map_to_world(Vector2(city_info.location[0], city_info.location[1] ))
	# The height of a tile if it were completely flat
	var expected_height = 65 * city_info.size[1]
	# Adjust the tile placement
	pos_on_grid.y -= (city_sprite.texture.get_height() - expected_height)
	pos_on_grid.x -= 28 * (city_info.size[0]-1)
	$"../BaseGrid".add_child(city_sprite)
	city_sprite.translate(pos_on_grid)
