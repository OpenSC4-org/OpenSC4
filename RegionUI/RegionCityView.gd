extends Area2D 
class_name RegionCityView

var region_view_thumbnails : Array = []
var savefile : DBPF
var city_info : SC4ReadRegionalCity

# Size, in pixels, of the tile base

var TILE_BASE_HEIGHT = 18
var TILE_BASE_WIDTH = 90


func init(filepath : String):
	savefile = DBPF.new(filepath)
	# Load the thumbnails
	# Note: should be 0, 2, 4, 6, but for some reason only 2 and 4 are ever present
	for instance_id in [0, 2]:
		region_view_thumbnails.append(savefile.get_subfile(0x8a2482b9, 0x4a2482bb, instance_id, ImageSubfile).get_as_texture())
	city_info = savefile.get_subfile(0xca027edb, 0xca027ee1, 0, SC4ReadRegionalCity)

func _ready():
	display()

func display(): # TODO city edges override other cities causing glitches, can be solved by controlling the draw order or by adding a z value
	# Print city size
	var pos_on_grid = get_parent().map_to_world(Vector2(city_info.location[0], city_info.location[1]))
	var thumbnail_texture : Texture = region_view_thumbnails[0]
	# The height of a tile if it were completely flat
	var expected_height = 63 * city_info.size[1]
	# Adjust the tile placement
	var extra_height = thumbnail_texture.get_height() - expected_height
	pos_on_grid.y -= extra_height
	pos_on_grid.x -= 38 * city_info.size[1]
	self.translate(pos_on_grid)
	$Thumbnail.texture = thumbnail_texture
	$CollisionShape.shape.extents = Vector2(thumbnail_texture.get_width() / 2, thumbnail_texture.get_height() / 2)

func get_total_pop():
	return city_info.population_residential

func save_thumbnail():
	region_view_thumbnails[0].get_data().save_png("region_view_thumbnail.png")

func open_city():
	Boot.current_city = savefile
	var err = get_tree().change_scene("res://City.tscn")
	if err != OK:
		print("Error trying to change the scene to the city")
