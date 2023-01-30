extends AudioStreamPlayer

const path_to_radio: String = '/Radio/Stations/Region/Music/%s'

var current_music 
var music_list = []
var rng = RandomNumberGenerator.new()

func _init():	
	self.load_music_files()

func _ready():
	var _unused = self.connect("finished", self, "play_music")

func play_music():
	self.current_music = self.music_list[rng.randi_range(0, len(self.music_list)- 1)]
	var file = File.new()
	file.open(Core.game_dir + path_to_radio % self.current_music, File.READ)

	var audiostream = AudioStreamMP3.new()
	audiostream.set_data(file.get_buffer(file.get_len()))
	self.set_stream(audiostream)
	self.play()


func load_music_files():
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
			self.music_list.append(file)
	dir.list_dir_end()

