extends Area2D 
class_name RegionCityView

var region_view_thumbnails : Array = []
var savefile : DBPF
var city_info : SC4ReadRegionalCity
var settings = {"borders":false}

# Size, in pixels, of the tile base

var TILE_BASE_HEIGHT = 18
var TILE_BASE_WIDTH = 90

var new_city_dialog_path = "res://scene/new_city_dialog.tscn"
var existing_city_dialog_path = "res://scene/existing_city_dialog.tscn"
var dialog : Node = null
#Shader
onready var outline_shader = preload("res://shaders/region_outline.shader")

func init(filepath : String):
	"""
	This is called from Region _ready
	Each save file means one region so filepath is .sc4
	"""
	
	savefile = DBPF.new(filepath)
	
	# Load the thumbnails
	# Note: should be 0, 2, 4, 6, but for some reason only 2 and 4 are ever present
	for instance_id in [0, 2]:
		region_view_thumbnails.append(savefile.get_subfile(0x8a2482b9, 0x4a2482bb, instance_id, ImageSubfile).get_as_texture())
	city_info = savefile.get_subfile(0xca027edb, 0xca027ee1, 0, SC4ReadRegionalCity)

func _ready():
	prepare_dialog()
	display()

func display(): # TODO city edges override other cities causing glitches, can be solved by controlling the draw order or by adding a z value
	# Print city size
	var pos_on_grid = get_parent().map_to_world(Vector2(city_info.location[0], city_info.location[1]))
	#var thumbnail_texture : Texture = region_view_thumbnails[0]
	# The height of a tile if it were completely flat
	#print(region_view_thumbnails[0].get_data().data["height"], region_view_thumbnails[0].get_data().data["width"], "\t", region_view_thumbnails[1].get_data().data["height"], region_view_thumbnails[1].get_data().data["width"])
	#var another = region_view_thumbnails[2].get_data()
	var mystery_img = region_view_thumbnails[1].get_data()
	var region_img = region_view_thumbnails[0].get_data()
	#another.save_png("user://another.png")
	mystery_img.save_png("user://mystery.png")
	region_img.save_png("user://region.png")
	mystery_img.lock()
	region_img.lock()
	var min_h = mystery_img.data["height"]
	var min_w = mystery_img.data["width"]
	for w in range(mystery_img.data["width"]):
		for h in range(mystery_img.data["height"]):
			var m_pix = mystery_img.get_pixel(w, h)
			if (m_pix.b) > 0.75:
				if h < min_h: min_h = h
				if w < min_w: min_w = w
				var border = Color(0.0, 0.0, 0.0, 0.0)
				if settings["borders"] == true:
					border = Color(m_pix.g/10, m_pix.g/10, m_pix.g/10, 0.0)
				var r_pix = (Color(m_pix.b, m_pix.b, m_pix.b, 1.0) * region_img.get_pixel(w, h)) + border
				region_img.set_pixel(w, h, r_pix)
			else:
				region_img.set_pixel(w, h, Color(0.0, 0.0, 0.0, 0.0))
	#var trim = Rect2(Vector2(float(min_w), float(min_h)), Vector2(mystery_img.data["width"], mystery_img.data["height"]))
	#var trimmed = region_img.get_rect(trim)
	var thumbnail_texture = ImageTexture.new()
	#region_img.save_png("user://region_done.png")
	thumbnail_texture.create_from_image(region_img, 0)
	var expected_height = 63.604 * city_info.size[1]
	# Adjust the tile placement
	var extra_height = thumbnail_texture.get_height() - expected_height
	pos_on_grid.y -= extra_height
	pos_on_grid.x -= 37.305 * city_info.size[1]
	self.translate(pos_on_grid)
	$Thumbnail.texture = thumbnail_texture
	$CollisionShape.shape.extents = Vector2(thumbnail_texture.get_width() / 2, thumbnail_texture.get_height() / 2)

func get_total_population() -> int:
	return city_info.get_total_population()

func save_thumbnail():
	region_view_thumbnails[0].get_data().save_png("region_view_thumbnail.png")

func open_city():
	Boot.current_city = savefile
	var err = get_tree().change_scene("res://CityView/CityScene/City.tscn")
	if err != OK:
		print("Error trying to change the scene to the city")

func on_mouse_hovered():	
	$Thumbnail.material = ShaderMaterial.new()
	$Thumbnail.material.shader = outline_shader

func on_mouse_unhovered():
	$Thumbnail.material = null
	
func on_select():
	toggle_dialog()
	
func on_unselect():
	toggle_dialog()
	
func toggle_dialog():
	Logger.info("Toggle Dialog")
	dialog.visible = !dialog.visible
	var center = get_texture_center()
	dialog.set_position(center)
	# TODO: Need to set the position of the dialog properly
	
func get_texture_center():
	var width = $Thumbnail.texture.get_width()
	var height = $Thumbnail.texture.get_height()
	var width_in_tilemap = width*sin(50)
	var height_in_tilemap = height*cos(50)
	Logger.info("W %d H %d wt %d ht %d" % [width, height, width_in_tilemap, height_in_tilemap])
	var center = Vector2(0, -height/2)
	return center
	
	
func prepare_dialog():
	"""
	When click on the RegionView the dialog pops up
	and it's tow types, start new city and continue 
	with already established city. Second one provides
	some additional information like: population in
	RCI and mayor rating etc.
	"""
	var dialog_res = null
	if self.city_info.is_populated():
		dialog_res = load(existing_city_dialog_path)
		dialog = dialog_res.instance()
		dialog.get_child(3).text = str(city_info.population_residential)
		dialog.get_child(4).text = str(city_info.population_commercial)
		dialog.get_child(5).text = str(city_info.population_industrial)
	else:
		dialog_res = load(new_city_dialog_path)
		dialog = dialog_res.instance()
		
	# Common for both dialog
	dialog.set_city_to_dialog(self)
		
	
	dialog.visible = false
	self.add_child(dialog)
	
	
	
