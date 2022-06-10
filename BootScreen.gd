extends Control

var loading_thread : Thread

func _ready():
	loading_thread = Thread.new()
	print("Booting OpenSC4...")
	var err = loading_thread.start(self, 'load_DATs')
	if err != OK:
		print("Error starting thread: " % err)
		return

func load_DATs():
	print("Loading DAT files...")
	$LoadProgress.value = 0
	load_single_DAT("simcity_dat_1", "res://SimCity_1.dat")
	load_single_DAT("simcity_dat_2", "res://SimCity_2.dat")
	load_single_DAT("simcity_dat_3", "res://SimCity_3.dat")
	load_single_DAT("simcity_dat_4", "res://SimCity_4.dat")
	load_single_DAT("simcity_dat_5", "res://SimCity_5.dat")
	load_single_DAT("_init", Boot.INI_location)
	load_single_DAT("sounds_file", "res://Sound.dat")
	load_single_DAT("intro_file", "res://Intro.dat")
	load_single_DAT("ep1_file", "res://EP1.dat")
	finish_loading()

func finish_loading():
	print("DAT files loaded")
	var err = get_tree().change_scene("res://Region.tscn")
	if err != OK:
		print("Error: %s" % err)
		return

func load_single_DAT(dst : String, src : String):
	$CurrentFileLabel.text = "Loading: %s" % src
	Boot.set(dst, DBPF.new(src))
	$LoadProgress.value += 12.5
