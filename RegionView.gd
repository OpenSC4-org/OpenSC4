extends Node2D

var REGION_NAME = "San Francisco"
var cities = {}
var SaveFileLoader = load("res://SaveFileLoader.gd")

func _init():
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
	print('City files: %s' % len(files))
	self.read_config_bmp()
	for f in files:
		var city = SaveFileLoader.new('res://Regions/%s/%s' % [REGION_NAME, f])
		self.add_child(city)

func _ready():
	for city in self.get_children():
		if city is SaveFileLoader:
			city.display()

func read_config_bmp():
	var region_config = Image.new()
	var err = region_config.load('res://Regions/%s/config.bmp' % REGION_NAME)
	if err != OK:
		print('Error loading region config: %s' % err)
		return
	# Iterate over the pixels
	var small_cities = 0;
	var large_cities = 0;
	var medium_cities = 0;
	region_config.lock()
	for i in range(region_config.get_width()):
		for j in range(region_config.get_height()):
			# Get the pixel at i,j
			var pixel = region_config.get_pixel(i, j)
			if pixel[0] == 1:
				small_cities += 1
				self.cities[[i, j]] = true
			elif pixel[1] == 1:
				medium_cities += 1
				self.cities[[i, j]] = true
				for k in range(2):
					for l in range(2):
						region_config.set_pixel(i + k, j + l, Color(0, 0, 0, 0))
			elif pixel[2] == 1:
				large_cities += 1
				self.cities[[i, j]] = true
				for k in range(4):
					for l in range(4):
						if k == 0 and l == 0:
							continue
						region_config.set_pixel(i + k, j + l, Color(0, 0, 0, 0))
	print('Small cities: %d' % small_cities)
	print('Medium cities: %d' % medium_cities)
	print('Large cities: %d' % large_cities)
	print('TOTAL: %d cities' % (small_cities + medium_cities + large_cities))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
