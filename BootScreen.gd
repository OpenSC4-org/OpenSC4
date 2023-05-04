extends Control

"""
Once everything is loaded the it changes to Region scene or the DAT explorer
"""


var config

var loading_thread : Thread
var dat_files : Array = [
						 "SimCity 4.ini",
						 "Sound.dat",
						 "Intro.dat",
						 "SimCity_1.dat",
						 "SimCity_2.dat",
						 "SimCity_3.dat",
						 "SimCity_4.dat",
						 "SimCity_5.dat",
						 "EP1.dat",]
						
func _ready():
	#_generate_types_dict_from_XML()
	config = INI.new("user://config.ini")
	if config.sections.size() > 0:
		Core.game_dir = config.sections["paths"]["sc4_files"]
	else:
		$dialog.popup_centered(get_viewport_rect().size / 2)
		await $dialog.popup_hide
		config.sections["paths"] = {}
		config.sections["paths"]["sc4_files"] = Core.game_dir
		config.save_file()
	
	#TODO check if files exist in current Core.game_dir
	var dir = Directory.new()
	var dir_complete = true
	while not dir_complete:
		if dir.open(Core.game_dir) == OK:
			dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			var files = []
			var file_name = dir.get_next()
			while file_name != "":
				files.append(file_name)
				file_name = dir.get_next()
			for dat in dat_files:
				if "/" in dat:
					var folders = dat.split('/')
					var folder_dir = ""
					for folder in range(len(folders)-1):
						folder_dir += ("/" + folders[folder])
					var file_n = folders[-1]
					var subdir = Directory.new()
					print(Core.game_dir+folder_dir)
					if subdir.open(Core.game_dir+folder_dir) == OK:
						subdir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
						var subfile_name = subdir.get_next()
						var found = false
						while subfile_name != "":
							if subfile_name == file_n:
								found = true
								break
							subfile_name = subdir.get_next()
						if not found:
							dir_complete = false
							print(dat, "not found")
					else:
						dir_complete = false
						print(dat, "not found")
						
				elif not files.has(dat):
					dir_complete = false
					print(dat, "not found")
		else:
			dir_complete = false
		if not dir_complete:
			$dialog.window_title = "dir was incomplete, select the SC4 installation folder"
			$dialog.popup_centered(get_viewport_rect().size / 2)
			await $dialog.popup_hide
			print("todo: store path in cfg.ini")
			config.sections["paths"] = {}
			config.sections["paths"]["sc4_files"] = Core.game_dir
			config.save_file()
	$dialog.deselect_all()
	$LoadProgress.value = 0
	loading_thread = Thread.new()
	Logger.info("Loading OpenSC4...")
	Logger.info("Using %s as game data folder" % Core.game_dir)
	# Would be nice to start multiple threads here not only one
	var err = loading_thread.start(Callable(self,'load_DATs'))
	if err != OK:
		Logger.error("Error starting thread: " % err)
		return

func _exit_tree():
	loading_thread.wait_to_finish()	

func load_DATs():
	for dat_file in dat_files :
		load_single_DAT(dat_file)
	finish_loading()

func finish_loading():
	Logger.info("DBPF files loaded")
	$NextScene.visible = true

func load_single_DAT(dat_file : String):
	var src = Core.game_dir + "/" + dat_file
	$CurrentFileLabel.text = "Loading: %s" % src 
	var dbpf = DBPF.new(src)
	#dbpf.DEBUG_show_all_subfiles_to_file(dat_file)
	Core.add_dbpf(dbpf)
	$LoadProgress.value += 100.0/len(dat_files)


func _on_dialog_confirmed():
	Core.game_dir = $dialog.current_dir

func _on_DATExplorerButton_pressed():
	print("here")
	var err = get_tree().change_scene_to_file("res://DATExplorer/DATExplorer.tscn")
	if err != OK:
		Logger.error("Error: %s" % err)

func _on_GameButton_pressed():
	var err = get_tree().change_scene_to_file("res://Region.tscn")
	if err != OK:
		Logger.error("Error: %s" % err)
	

