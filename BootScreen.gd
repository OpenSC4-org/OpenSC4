extends Control
	
var cfg_file

var loading_thread : Thread
var dat_files : Array = [
						 "Apps/SimCity 4.ini",
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
	cfg_file = INISubfile.new("user://cfg.ini")
	if cfg_file.sections.size() > 0:
		Core.game_dir = cfg_file.sections["paths"]["sc4_files"]
	else:
		$dialog.popup_centered(get_viewport_rect().size / 2)
		yield($dialog, "popup_hide")
		print("todo: store path in cfg.ini")
		cfg_file.sections["paths"] = {}
		cfg_file.sections["paths"]["sc4_files"] = Core.game_dir
		cfg_file.save_file()
	
	#TODO check if files exist in current Core.game_dir
	var dir = Directory.new()
	var dir_complete = true
	while not dir_complete:
		if dir.open(Core.game_dir) == OK:
			dir.list_dir_begin()
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
						subdir.list_dir_begin()
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
			yield($dialog, "popup_hide")
			print("todo: store path in cfg.ini")
			cfg_file.sections["paths"] = {}
			cfg_file.sections["paths"]["sc4_files"] = Core.game_dir
			cfg_file.save_file()
	$dialog.deselect_items()
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
		load_single_DAT(Core.game_dir + "/" + dat_file)
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
	Core.game_dir = $dialog.current_dir
	
func _generate_types_dict_from_XML():
	"""
	Used to generate exemplar_types.dict from properties.xml
	since this is quite slow I chose to store the results in a dict file that I assume loads faster
	The hex values are stored as int to make matching easyer in ExemplarSubfile
	"""
	var xml_file = File.new()
	xml_file.open("res://properties.xml", File.READ)
	var xml_text = xml_file.get_as_text()
	xml_file.close()
	var type_dict = {}
	var reg_key = RegEx.new()
	reg_key.compile("(?:num=\\D)(\\w*)")
	var reg_val = RegEx.new()
	reg_val.compile("((?<!(group\\s))name=\")((?:(?!\").)*)")
	var keys = []
	for key in reg_key.search_all(xml_text):
		var string = key.get_string(1).split("x")[1]
		var str_int = ("0x00" + string.substr(0, 4)).hex_to_int()<<16
		str_int += ("0x00" + string.substr(4, 4)).hex_to_int()
		keys.append(str_int)
	var vals = []
	for val in reg_val.search_all(xml_text):
		vals.append(val.get_string(3))
		
	var xml_file_tropod = File.new()
	xml_file_tropod.open("res://tropod_Properties.xml", File.READ)
	xml_text = xml_file_tropod.get_as_text()
	xml_file_tropod.close()
	for key in reg_key.search_all(xml_text):
		var string = key.get_string(1).split("x")[1]
		var str_int = ("0x00" + string.substr(0, 4)).hex_to_int()<<16
		str_int += ("0x00" + string.substr(4, 4)).hex_to_int()
		keys.append(str_int)
	for val in reg_val.search_all(xml_text):
		vals.append(val.get_string(3))
		
	for i in range(len(keys)):
		type_dict[keys[i]] = vals[i]
	var t_file = File.new()
	t_file.open("res://exemplar_types.dict", File.WRITE)
	t_file.store_string(var2str(type_dict))
	t_file.close()
