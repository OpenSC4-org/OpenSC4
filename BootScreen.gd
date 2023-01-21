extends Control

"""
Once everything is loaded the it changes to Region scene.
"""


var config

var loading_thread : Thread
var dat_files : Array = [
						 "original_data_files/SimCity 4.ini",
						 "original_data_files/Sound.dat",
						 "original_data_files/Intro.dat",
						 "original_data_files/SimCity_1.dat",
						 "original_data_files/SimCity_2.dat",
						 "original_data_files/SimCity_3.dat",
						 "original_data_files/SimCity_4.dat",
						 "original_data_files/SimCity_5.dat",
						 "original_data_files/EP1.dat",]
						
func load_user_configuration():
	config = ConfigFile.new()
	var error = config.load("user://config.ini")
	if error == ERR_FILE_NOT_FOUND:
		Logger.warn("File config.ini was not found.")
		Logger.warn("New configuration file will be created.")
	elif error != 0:
		Logger.error("An error occured: %d." %[error])
		Logger.warn("New configuration file will be created.")
	return config
	
func get_gamedir_path(config):
	# Try to get the game dir path from configuration
	# if it is not there then dialog popups
	var path = config.get_value("paths", "sc4_files")
	if not path:
		$dialog.popup_centered(get_viewport_rect().size / 2)		
		yield($dialog, "popup_hide")
		path = $dialog.current_dir
		config.set_value("paths", "sc4_files", path)
		config.save("user://config.ini")
	return path
		
func _ready():
	var config = load_user_configuration()
	
	Core.game_dir = get_gamedir_path(config)

	$LoadProgress.value = 0
	loading_thread = Thread.new()
	Logger.info("Loading OpenSC4...")
	# Would be nice to start multiple threads here not only one
	var err = loading_thread.start(self, 'load_DATs')
	if err != OK:
		Logger.erorr("Error starting thread: " % err)
		return
	


func _exit_tree():
	loading_thread.wait_to_finish()	

func load_DATs():
	for dat_file in dat_files :
		load_single_DAT(dat_file)
	finish_loading()

func finish_loading():
	Logger.info("DBPF files loaded")
	var err = get_tree().change_scene("res://Region.tscn")
	if err != OK:
		Logger.error("Error: %s" % err)

func load_single_DAT(dat_file : String):
	var src = Core.game_dir + "/" + dat_file
	$CurrentFileLabel.text = "Loading: %s" % src 
	var dbpf = DBPF.new(src)
	#dbpf.DEBUG_show_all_subfiles_to_file(dat_file)
	Core.add_dbpf(dbpf)
	$LoadProgress.value += 100.0/len(dat_files)


func _on_dialog_confirmed():
	Core.game_dir = $dialog.current_dir
	

