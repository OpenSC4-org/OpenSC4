extends Control

var loading_thread : Thread
var dat_files : Array = [
						 Boot.INI_location,
						 "res://Sound.dat",
						 "res://Intro.dat",
						 "res://SimCity_1.dat",
						 "res://SimCity_2.dat",
						 "res://SimCity_3.dat",
						 "res://SimCity_4.dat",
						 "res://SimCity_5.dat",
						 "res://EP1.dat",]

func _ready():
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
		load_single_DAT(dat_file)
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
