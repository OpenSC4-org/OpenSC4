extends Node2D

var REGION_NAME = "Timbuktu"
var total_population = 0
var region_w = 0
var region_h = 0
var cities = {}
var radio = []
var current_music 
var rng = RandomNumberGenerator.new()
var custom_ui_classes = {
	# Main region UI
	"0x098f4f6c":preload("res://RegionUI/DisplaySettingsButton.gd"),
	"0x09ebe9ee":preload("res://RegionUI/NameAndPopulation.gd"),
	"0x09ebee45":preload("res://RegionUI/RegionSubmenu.gd"),
	"0x09ebee60":preload("res://RegionUI/TopBarSettingsMenu.gd"),
	"0x09ebf2bd":preload("res://RegionUI/RegionManagementButton.gd"),
	"0x09ebf2c3":preload("res://RegionUI/TopBarSettingsButton.gd"),
	"0x0a5510a9":preload("res://RegionUI/GameSettingsButton.gd"),
	"0x26c10a3e":preload("res://RegionUI/ExitGameButton.gd"),
	"0x2a5b0000":preload("res://RegionUI/NewRegionButton.gd"),
	"0x2a5b0001":preload("res://RegionUI/BrowseRegionsButton.gd"),
	"0x2a5b0002":preload("res://RegionUI/DeleteRegionButton.gd"),
	"0x2ba290c1":preload("res://RegionUI/ViewOptionsContainer.gd"),
	"0x4a779a1a":preload("res://RegionUI/InternetButton.gd"),
	"0x6a91dc14":preload("res://RegionUI/TopBarDecoration.gd"),
	"0x6a91dc15":preload("res://RegionUI/TopBarSettingsButtonContainer.gd"),
	"0x6a91dc16":preload("res://RegionUI/TopBarButtons.gd"),
	"0x8a1da655":preload("res://RegionUI/SaveScreenshotButton.gd"),
	"0xa98f4f88":preload("res://RegionUI/AudioSettingsButton.gd"),
	"0xaba290e1":preload("res://RegionUI/SatelliteViewRadioButton.gd"),
	"0xc9e41918":preload("res://RegionUI/PopulationIndicator.gd"),
	"0xca1da670":preload("res://RegionUI/BrowseScreenshotsButton.gd"),
	"0xca5cfee2":preload("res://RegionUI/ShowNamesCheckbox.gd"),
	"0xcba290ec":preload("res://RegionUI/TransportationViewRadioButton.gd"),
	"0xea5a96e6":preload("res://RegionUI/ShowBordersCheckbox.gd"),
	"0xea5bd179":preload("res://RegionUI/RegionNameDisplay.gd"),
	"0xea8cad19":preload("res://RegionUI/Compass.gd"),
	# Region prompts
}

func _init():
	Logger.info("Initializing the region view")
	
	# Open the region INI file
	#var _ini = INISubfile.new("res://Regions/%s/region.ini" % REGION_NAME)


func anchror_sort(a, b):
	if a[0] != b[0]: # non draw
		return a[0] < b[0]
	else: # bigger tile first
		return a[2] > b[2]

func _ready():
	Logger.info("Region node is ready")	
	var total_pop = 0
	for city in self.get_children():
		if city is RegionCityView:
			city.display()
			total_pop += city.get_total_pop()
	Logger.info("Total population: %d" % [total_pop])
	# Count the city files in the region folder
	# City files end in .sc4
	var files = []
	var dir = Directory.new()
	var region_dir_full_path = Core.get_gamedata_path('Regions/%s/' % REGION_NAME)
	var err = dir.open(region_dir_full_path)
	if err != OK:
		Logger.error('Error opening region directory \'%s\': %s' % [region_dir_full_path, err])
		return
	dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with('.sc4'):
			files.append(file)
	dir.list_dir_end()
	self.read_config_bmp()
	var anchor = []
	for f in files:
		var city = load("res://RegionUI/RegionCityView.tscn").instantiate()
		city.init(Core.get_gamedata_path('Regions/%s/%s' % [REGION_NAME, f]))
		var x : int = city.city_info.location[0]
		var y : int = city.city_info.location[1]
		var width : int = city.city_info.size[0]
		var height : int = city.city_info.size[1]
		self.total_population += city.city_info.population_residential
		var vert_comp = (x+width) + (y+height) - width
		anchor.append([vert_comp, city, width])
	anchor.sort_custom(Callable(self,"anchror_sort"))
	
	for anch in anchor:
		var city = anch[1]
		var x : int = city.city_info.location[0]
		var y : int = city.city_info.location[1]
		var width : int = city.city_info.size[0]
		var height : int = city.city_info.size[1]
		for i in range(x, x+width):
			for j in range(y, y+height): 
				$BaseGrid.cities[i][j] = city
		$BaseGrid.add_child(city)
	$RadioPlayer.play_music()	
	load_ui()

func read_config_bmp():
	var region_config_file = File.new()
	region_config_file.open(Core.get_gamedata_path("Regions/%s/config.bmp" % REGION_NAME), File.READ)
	var data = region_config_file.get_buffer(region_config_file.get_length())
	var region_config = Image.new()
	region_config.load_bmp_from_buffer(data)

	# Iterate over the pixels
	$BaseGrid.init_cities_array(region_config.get_width(), region_config.get_height())
	region_w = region_config.get_width()
	region_h = region_config.get_height()
	false # region_config.lock() # TODOConverter40, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed	
	for i in range(region_config.get_width()):
		for j in range(region_config.get_height()):
			# Get the pixel at i,j
			var pixel = region_config.get_pixel(i, j)
			if pixel[0] == 1: # small tile
				self.cities[[i, j]] = true
			elif pixel[1] == 1: # medium tile
				self.cities[[i, j]] = true
				for k in range(2):
					for l in range(2):
						region_config.set_pixel(i + k, j + l, Color(0, 0, 0, 0))
			elif pixel[2] == 1: # large tile
				self.cities[[i, j]] = true
				for k in range(4):
					for l in range(4):
						if k == 0 and l == 0:
							continue
						region_config.set_pixel(i + k, j + l, Color(0, 0, 0, 0))
	

func close_all_prompts():
	for city in $BaseGrid.get_children():
		if city is RegionCityView:
			city.visible = true
			var prompt = city.get_node_or_null("UnincorporatedCityPrompt")
			if prompt != null:
				prompt.queue_free()
				
func _DEBUG_extract_files(type_id, group_id):
	var list_of_instances = Core.get_list_instances(type_id, group_id)
	if type_id == "PNG":
		for item in list_of_instances:
			# Filter bad numbers, maybe holes? I don't know
			if item in [1269886195,339829152, 339829153, 
						339829154, 339829155, 1809881377, 
						1809881378, 1809881379, 1809881380,
						1809881381, 1809881382, 3929989376,
						3929989392, 3929989408, 3929989424,
						3929989440, 3929989456, 338779648,
						338779664, 338779680, 338779696,
						338779712, 338779728, 338779729,
						733031711, 3413654842]:
				continue
			var subfile = Core.get_subfile(type_id, group_id, item)
			var img = subfile.get_as_texture().get_data()
			var path = "user://%s/%s/%s.png" % [type_id, group_id, item]
			#var path = "user://UI/%s.png" % [item]
			img.save_png(path)
	else:
		Logger.wanr("Type: %s is not yet implemented." % type_id)

func build_button(button, instance_id):
	var btn_img = Core.get_subfile("PNG", "UI_IMAGE", instance_id)
	button.texture_disabled = AtlasTexture.new()
	button.texture_disabled.atlas = btn_img.get_as_texture()
	button.texture_disabled.region = Rect2(0, 0, 80 ,60)
	
	button.texture_normal = AtlasTexture.new()
	button.texture_normal.atlas = btn_img.get_as_texture()
	button.texture_normal.region = Rect2(80, 0, 80 ,60)
	
	button.texture_pressed = AtlasTexture.new()
	button.texture_pressed.atlas = btn_img.get_as_texture()
	button.texture_pressed.region = Rect2(160, 0, 80 ,60)
	
	button.texture_hover = AtlasTexture.new()
	button.texture_hover.atlas = btn_img.get_as_texture()
	button.texture_hover.region = Rect2(240, 0, 80 ,60)


func build_top_buttons():
	build_button($UICanvas.get_child(2).get_child(1).get_child(0), 339829505)
	build_button($UICanvas.get_child(2).get_child(1).get_child(1), 339829506)
	build_button($UICanvas.get_child(2).get_child(1).get_child(2), 339829507)

func load_ui():
	preload("res://addons/dbpf/GZWinBtn.gd")
	var ui = Core.subfile(0x0, 0x96a006b0, 0xaa920991, SC4UISubfile)
	ui.add_to_tree($UICanvas, self.custom_ui_classes)
