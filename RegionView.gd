extends Node2D

var REGION_NAME = "Berlin"
var cities = {}
var radio = []
var current_music 
var rng = RandomNumberGenerator.new()

func _init():
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
	$RadioPlayer.play()


func _ready():
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
	for f in files:
		var city = load("res://RegionUI/RegionCityView.tscn").instance()
		city.init('res://Regions/%s/%s' % [REGION_NAME, f])
		$BaseGrid.add_child(city)

func read_config_bmp():
	var region_config = Image.new()
	region_config.load("res://Regions/%s/config.bmp" % REGION_NAME)
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

func close_all_prompts():
	for city in $BaseGrid.get_children():
		if city is RegionCityView:
			var prompt = city.get_node_or_null("UnincorporatedCityPrompt")
			if prompt != null:
				prompt.queue_free()
