extends Control
	
var game_dir = null
var cfg_file

var loading_thread : Thread
var dat_files : Array = [
						 "/Apps/SimCity 4.ini",
						 "/Sound.dat",
						 "/Intro.dat",
						 "/SimCity_1.dat",
						 "/SimCity_2.dat",
						 "/SimCity_3.dat",
						 "/SimCity_4.dat",
						 "/SimCity_5.dat",
						 "/EP1.dat",]

func _ready():
	
	cfg_file = INISubfile.new("user://cfg.ini")
	if cfg_file.sections.size() > 0:
		game_dir = cfg_file.sections["paths"]["sc4_files"]
	else:
		$dialog.popup_centered(get_viewport_rect().size / 2)
		yield($dialog, "popup_hide")
		print("todo: store path in cfg.ini")
		cfg_file.sections["paths"] = {}
		cfg_file.sections["paths"]["sc4_files"] = game_dir
		cfg_file.save_file()
	
	#TODO check if files exist in current game_dir
	var dir = Directory.new()
	var dir_complete = false
	while not dir_complete:
		if dir.open(game_dir) == OK:
			dir.list_dir_begin()
			var files = []
			var file_name = dir.get_next()
			while file_name != "":
				files.append(file_name)
				file_name = dir.get_next()
			for dat in dat_files:
				if not files.has(dat):
					dir_complete = false
		else:
			dir_complete = false
		if not dir_complete:
			$dialog.window_title = "dir was incomplete, select the SC4 installation folder"
			$dialog.popup_centered(get_viewport_rect().size / 2)
			yield($dialog, "popup_hide")
			print("todo: store path in cfg.ini")
			cfg_file.sections["paths"] = {}
			cfg_file.sections["paths"]["sc4_files"] = game_dir
			cfg_file.save_file()
		
	loading_thread = Thread.new()
	print("Booting OpenSC4...")
	var err = loading_thread.start(self, 'load_DATs')
	if err != OK:
		print("Error starting thread: " % err)
		return

func _exit_tree():
	loading_thread.wait_to_finish()

func load_DATs():
	print("Loading DAT files...")
	$LoadProgress.value = 0
	for dat_file in dat_files :
		load_single_DAT(game_dir + dat_file)
	finish_loading()

func finish_loading():
	print("DAT files loaded")
	var err = get_tree().change_scene("res://Region.tscn")
	if err != OK:
		print("Error: %s" % err)
		return

func load_single_DAT(src : String):
	$CurrentFileLabel.text = "Loading: %s" % src
	Core.add_dbpf(DBPF.new(src))
	$LoadProgress.value += 100.0/len(dat_files)


func _on_dialog_confirmed():
	game_dir = $dialog.current_dir
