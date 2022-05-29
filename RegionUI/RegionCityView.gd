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

func _ready():
	city_info = savefile.get_subfile(0xca027edb, 0xca027ee1, 0, SC4ReadRegionalCity)
	display()

func display():
	# Print city size
	var pos_on_grid = get_parent().map_to_world(Vector2(city_info.location[0], city_info.location[1] ))
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

func _input_event(_viewport: Object, event: InputEvent, _shape_idx : int) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		# get the texture's pixel
		var img = $Thumbnail.texture.get_data()
		img.lock()
		var relative_position = event.get_global_position() - self.position
		var pixel_clicked = img.get_pixel(relative_position.x, relative_position.y)
		if pixel_clicked.a < 1:
			return
		img.unlock()
		self.on_click()
		self.visible = false

func save_thumbnail():
	region_view_thumbnails[0].get_data().save_png("region_view_thumbnail.png")

func on_click():
	var region = get_parent().get_parent()
	region.close_all_prompts()
	var prompt = preload("res://RegionUI/UnincorporatedCityPrompt.tscn").instance()
	add_child(prompt)
	pass
