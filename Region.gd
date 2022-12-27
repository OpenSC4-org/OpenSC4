extends Node2D

var REGION_NAME = "Timbuktu"
var region_w = 0
var region_h = 0
var cities = {}




func _init():
	print("Initializing the region view")
	
	# Open the region INI file
	var _ini = INISubfile.new("res://Regions/%s/region.ini" % REGION_NAME)


func anchror_sort(a, b):
	if a[0] != b[0]: # non draw
		return a[0] < b[0]
	else: # bigger tile first
		return a[2] > b[2]

func _ready():
	print("Region node is ready")	
	$RadioPlayer.play_music()
	var total_pop = 0
	for city in self.get_children():
		if city is RegionCityView:
			city.display()
			total_pop += city.get_total_pop()
	# Count the city files in the region folder
	# City files end in .sc4
	var files = []
	var dir = Directory.new()
	var err = dir.open(Core.game_dir + '/Regions/%s/' % REGION_NAME)
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

#func load_ui():
	#pass
	#var ui = Core.subfile(0x0, 0x96a006b0, 0xaa920991, SC4UISubfile)
	#$UICanvas.add_child(ui.root)
