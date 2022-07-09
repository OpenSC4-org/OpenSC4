extends Node2D

var REGION_NAME = "Timbuktu"
var region_w = 0
var region_h = 0
var cities = {}
var radio = []
var current_music 
var rng = RandomNumberGenerator.new()

class Tile_c:
	"class used to bundle tile data"
	var x
	var y
	var size
	var city
	var edges
	var cleared
	func _init(x_in, y_in, size_in, city_in):
		self.x = x_in
		self.y = y_in
		self.size = size_in
		self.city = city_in
		self.edges = edges_to_free(x, y, size)
		self.cleared = edges_cleared(x, y, size)
	
	func edges_to_free(x, y, size):
		"edges to free generates edges that need to be drawn before this tile object to prevent overlapping"
		var edges = []
		for c_it in range(size):
			if y > 0:
				edges.append([true, c_it+x, y])
			if x > 0:
				edges.append([false, x, c_it + y])
		return edges
		
	func edges_cleared(x, y, size):
		"edges cleared generates edges are drawn and clear other tiles to be drawn"
		var edges = []
		for c_it in range(size):
			edges.append([true, c_it+x, y+size])
			edges.append([false, x+size, c_it + y])
		return edges

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
	$UICanvas/UI/RegionNameLabel.text = REGION_NAME
	$RadioPlayer.connect("finished", self, "play_new_random_music")
	play_new_random_music()
	var total_pop = 0
	for city in self.get_children():
		if city is RegionCityView:
			city.display()
			total_pop += city.get_total_pop()
	$UICanvas/UI/RegionPopLabel.text = str(total_pop)
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
		var vert_comp = (x+width) + (y+height)
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
	load_ui_images()
	


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

func load_ui_images():
	var simcity_dat_1 = Boot.simcity_dat_1
	var REGION_VIEW_UI = 0x14416300
	var REGION_INFO_BASE = REGION_VIEW_UI | 0x00
	var REGION_TOP_REGIONS = REGION_VIEW_UI | 0x01
	var REGION_TOP_INTERNET =  REGION_VIEW_UI | 0x02
	var REGION_TOP_EXIT = REGION_VIEW_UI | 0x03
	var REGION_TOP_RIGHT = REGION_VIEW_UI | 0x04
	var REGION_TOP_REGIONS_POPUP_BG = REGION_VIEW_UI | 0x07
	var REGION_TOP_INTERNET_POPUP_BG = REGION_VIEW_UI | 0x08
	var REGION_TOP_RIGHT_UI = REGION_VIEW_UI | 0x0d
	var REGION_TOP_UI = REGION_VIEW_UI | 0x0f
	var REGION_DELETE_REGION = REGION_VIEW_UI | 0x12
	var REGION_OPEN_FOLDER = REGION_VIEW_UI | 0x13
	var REGION_NEW_REGION = REGION_VIEW_UI | 0x14
	var REGION_CHECKBOX = REGION_VIEW_UI | 0x15
	var REGION_RADIOBUTTON = REGION_VIEW_UI | 0x16
	var REGION_EMPTY_CITY_DIALOG = REGION_VIEW_UI | 0x21
	var REGION_CITY_DIALOG = REGION_VIEW_UI | 0x22
	var REGION_CLOSE_DIALOG = REGION_VIEW_UI | 0x23
	var REGION_DELETE_CITY = REGION_VIEW_UI | 0x24
	var REGION_IMPORT_CITY = REGION_VIEW_UI | 0x25
	var REGION_OPEN_CITY = REGION_VIEW_UI | 0x26
	var region_info_ui_sprite = simcity_dat_1.get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_INFO_BASE, ImageSubfile)
	$UICanvas/UI/Background.texture = region_info_ui_sprite.get_as_texture()
	$UICanvas/UI/TopUI.texture = simcity_dat_1.get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_UI, ImageSubfile).get_as_texture()
	$UICanvas/UI/RegionManagement.from_dbpf(simcity_dat_1, SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_REGIONS)
	$UICanvas/UI/Internet.from_dbpf(simcity_dat_1, SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_INTERNET)
	$UICanvas/UI/Exit.from_dbpf(simcity_dat_1, SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_EXIT)
	$UICanvas/UI/TopRight.from_dbpf(simcity_dat_1, SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_RIGHT)
	$UICanvas/UI/RegionPopupBackground.texture = simcity_dat_1.get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_REGIONS_POPUP_BG, ImageSubfile).get_as_texture()
	$UICanvas/UI/InternetPopupBackground.texture = simcity_dat_1.get_subfile(SubfileTGI.TYPE_PNG, 0x1ABE787D, REGION_TOP_INTERNET_POPUP_BG, ImageSubfile).get_as_texture()
	$UICanvas/SpritesDBG.set_visible(false)
