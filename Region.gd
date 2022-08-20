extends Node2D

var REGION_NAME = "Timbuktu"
var total_population = 0
var region_w = 0
var region_h = 0
var cities = {}
var radio = []
var current_music 
var rng = RandomNumberGenerator.new()

func _init():
	print("Initializing the region view")
	rng.randomize()
	# Open the region INI file
	var _ini = INISubfile.new("res://Regions/%s/region.ini" % REGION_NAME)

	# Load the music list
	var dir = Directory.new()
	var err = dir.open('res://Radio/Stations/Region/Music')
	if err != OK:
		print('Error opening radio directory: %s' % err)
		return
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with('.mp3'):
			self.radio.append(file)
	dir.list_dir_end()

func play_new_random_music():
	self.current_music = self.radio[rng.randi_range(0, len(self.radio)- 1)]
	var file = File.new()
	file.open('res://Radio/Stations/Region/Music/%s' % self.current_music, File.READ)

	var audiostream = AudioStreamMP3.new()
	audiostream.set_data(file.get_buffer(file.get_len()))
	$RadioPlayer.set_stream(audiostream)
	#$RadioPlayer.play()

func anchror_sort(a, b):
	if a[0] != b[0]: # non draw
		return a[0] < b[0]
	else: # bigger tile first
		return a[2] > b[2]

func _ready():
	print("Region node is ready")
	$RadioPlayer.connect("finished", self, "play_new_random_music")
	play_new_random_music()
	var total_pop = 0
	for city in self.get_children():
		if city is RegionCityView:
			city.display()
			total_pop += city.get_total_pop()
	# Count the city files in the region folder
	# City files end in .sc4
	var files = []
	var dir = Directory.new()
	var err = dir.open('res://Regions/%s/' % REGION_NAME)
	if err != OK:
		print('Error opening region directory: %s' % err)
		return
	dir.list_dir_begin()
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
		var city = load("res://RegionUI/RegionCityView.tscn").instance()
		city.init('res://Regions/%s/%s' % [REGION_NAME, f])
		var x : int = city.city_info.location[0]
		var y : int = city.city_info.location[1]
		var width : int = city.city_info.size[0]
		var height : int = city.city_info.size[1]
		self.total_population += city.city_info.population_residential
		var vert_comp = (x+width) + (y+height) - width
		anchor.append([vert_comp, city, width])
	anchor.sort_custom(self, "anchror_sort")
	
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
	load_ui()

func read_config_bmp():
	var region_config = load("res://Regions/%s/config.bmp" % REGION_NAME).get_data()
	# Iterate over the pixels
	$BaseGrid.init_cities_array(region_config.get_width(), region_config.get_height())
	region_w = region_config.get_width()
	region_h = region_config.get_height()
	region_config.lock()	
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

func load_ui():
	preload("res://addons/dbpf/GZWinBtn.gd")
	var custom_ui_classes = {}
	custom_ui_classes["0x6a91dc14"] = preload("res://RegionUI/TopBarDecoration.gd")
	custom_ui_classes["0x6a91dc16"] = preload("res://RegionUI/TopBarButtons.gd")
	custom_ui_classes["0x6a91dc15"] = preload("res://RegionUI/TopBarSettingsButtonContainer.gd")
	custom_ui_classes["0x09ebee60"] = preload("res://RegionUI/TopBarSettingsMenu.gd")
	custom_ui_classes["0x09ebe9ee"] = preload("res://RegionUI/NameAndPopulation.gd")
	custom_ui_classes["0x09ebee45"] = preload("res://RegionUI/RegionSubmenu.gd")
	custom_ui_classes["0xea8cad19"] = preload("res://RegionUI/Compass.gd")
	custom_ui_classes["0x2a5b0000"] = preload("res://RegionUI/NewRegionButton.gd")
	custom_ui_classes["0x2a5b0001"] = preload("res://RegionUI/BrowseRegionsButton.gd")
	custom_ui_classes["0x2a5b0002"] = preload("res://RegionUI/DeleteRegionButton.gd")
	#custom_ui_classes["0x2ba290c1"] = preload("res://RegionUI/ViewOptionsContainer.gd")
	custom_ui_classes["0xaba290e1"] = preload("res://RegionUI/SatelliteViewRadioButton.gd")
	custom_ui_classes["0xcba290ec"] = preload("res://RegionUI/TransportationViewRadioButton.gd")
	custom_ui_classes["0x09ebf2bd"] = preload("res://RegionUI/RegionManagementButton.gd")
	custom_ui_classes["0x4a779a1a"] = preload("res://RegionUI/InternetButton.gd")
	custom_ui_classes["0x26c10a3e"] = preload("res://RegionUI/ExitGameButton.gd")
	custom_ui_classes["0xea5bd179"] = preload("res://RegionUI/RegionNameDisplay.gd")
	custom_ui_classes["0xc9e41918"] = preload("res://RegionUI/PopulationIndicator.gd")
	custom_ui_classes["0x09ebf2c3"] = preload("res://RegionUI/TopBarSettingsButton.gd")

	custom_ui_classes["0x8a1da655"] = preload("res://RegionUI/SaveScreenshotButton.gd")
	custom_ui_classes["0xca1da670"] = preload("res://RegionUI/BrowseScreenshotsButton.gd")
	custom_ui_classes["0x098f4f6c"] = preload("res://RegionUI/DisplaySettingsButton.gd")
	custom_ui_classes["0x0a5510a9"] = preload("res://RegionUI/GameSettingsButton.gd")
	custom_ui_classes["0xa98f4f88"] = preload("res://RegionUI/AudioSettingsButton.gd")

	custom_ui_classes["0xca5cfee2"] = preload("res://RegionUI/ShowNamesCheckbox.gd")
	custom_ui_classes["0xea5a96e6"] = preload("res://RegionUI/ShowBordersCheckbox.gd")


	var ui = Core.subfile(0x0, 0x96a006b0, 0xaa920991, SC4UISubfile)
	ui.add_to_tree($UICanvas, custom_ui_classes)
