extends Node2D

var REGION_NAME = "Timbuktu"
var cities = {}
var SC4SaveFile = load("res://SC4SaveFile.gd")
var INILoader = load("res://INILoader.gd")
var radio = []
var current_music 
var rng = RandomNumberGenerator.new()

func _init():
	rng.randomize()
	# Open the region INI file
	var _ini = INILoader.new("res://Regions/%s/region.ini" % REGION_NAME)
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
	for f in files:
		var city = SC4SaveFile.new('res://Regions/%s/%s' % [REGION_NAME, f])
		self.add_child(city)

	# Open a random music file
	err = dir.open('res://Radio/Stations/Region/Music')
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
	$RadioPlayer.play()


func _ready():
	$UICanvas/UI/RegionInfoUI/RegionNameLabel.text = REGION_NAME
	$RadioPlayer.connect("finished", self, "play_new_random_music")
	play_new_random_music()
	var total_pop = 0
	for city in self.get_children():
		if city is SC4SaveFile:
			city.display()
			total_pop += city.get_total_pop()
	$UICanvas/UI/RegionInfoUI/RegionPopLabel.text = str(total_pop)
	$"../intro_png".queue_free()
	# Count the total inhabitants of the region
	# Iterate over each city info subfile

func read_config_bmp():
	var region_config = Image.new()
	var err = region_config.load('res://Regions/%s/config.bmp' % REGION_NAME)
	if err != OK:
		print('Error loading region config: %s' % err)
		return
	# Iterate over the pixels
	region_config.lock()
	for i in range(region_config.get_width()):
		for j in range(region_config.get_height()):
			# Get the pixel at i,j
			var pixel = region_config.get_pixel(i, j)
			if pixel[0] == 1:
				self.cities[[i, j]] = true
			elif pixel[1] == 1:
				self.cities[[i, j]] = true
				for k in range(2):
					for l in range(2):
						region_config.set_pixel(i + k, j + l, Color(0, 0, 0, 0))
			elif pixel[2] == 1:
				self.cities[[i, j]] = true
				for k in range(4):
					for l in range(4):
						if k == 0 and l == 0:
							continue
						region_config.set_pixel(i + k, j + l, Color(0, 0, 0, 0))
