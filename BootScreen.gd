extends Control

func _ready():
	print("Booting OpenSC4...")
	load_DAT()
	var err = get_tree().change_scene("res://Region.tscn")
	if err != OK:
		print("Error: %s" % err)
		return

func load_DAT():
	print("Loading DAT files...")
	$LoadProgress.value = 0
	var _ini = INISubfile.new(Boot.INI_location)
	$LoadProgress.value += 12.5
	Boot.simcity_dat_1 = DBPF.new("res://SimCity_1.dat")
	$LoadProgress.value += 12.5
	Boot.simcity_dat_2 = DBPF.new("res://SimCity_2.dat")
	$LoadProgress.value += 12.5
	Boot.simcity_dat_3 = DBPF.new("res://SimCity_3.dat")
	$LoadProgress.value += 12.5
	Boot.simcity_dat_4 = DBPF.new("res://SimCity_4.dat")
	$LoadProgress.value += 12.5
	Boot.simcity_dat_5 = DBPF.new("res://SimCity_5.dat")
	$LoadProgress.value += 12.5
	Boot.sounds_file = DBPF.new("res://Sound.dat")
	$LoadProgress.value += 12.5
	Boot.intro_file = DBPF.new("res://Intro.dat")
	$LoadProgress.value += 12.5
	Boot.ep1_file = DBPF.new("res://EP1.dat")
	$LoadProgress.value += 12.5
	print("DAT files loaded")
