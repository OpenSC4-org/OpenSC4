extends Node2D

var REGION_NAME = "Timbuktu"
var region_w = 0
var region_h = 0
var cities = {}




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
	$RadioPlayer.play_music()
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
	var err = dir.open(Core.game_dir + '/Regions/%s/' % REGION_NAME)
	if err != OK:
		Logger.error('Error opening region directory: %s' % err)
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

func load_ui():
	Logger.info("Starting to load some UI pictures...")
	
	
	#var subfile = Core.get_FSH_subfile(0x46a006b0, 0xab7052bd)
	#var subfile = Core.subfile(0x856ddbac,0x1ABE787D, 0xcc1a735d, ImageSubfile)
	var type_id = "PNG"
	var groups = Core.get_list_groups(type_id)
	print(groups)
	var group_id = "UI_IMAGE"
	var image = Core.get_subfile("PNG", "UI_IMAGE", 339829504)
	var tex = image.get_as_texture()
	$UICanvas.get_child(1).get_child(0).texture = tex
	# self._DEBUG_extract_files(type_id, group_id)
	
	
			
	#pass
	#var ui = Core.subfile(0x0, 0x96a006b0, 0xaa920991, SC4UISubfile)
	#$UICanvas.add_child(ui.root)
