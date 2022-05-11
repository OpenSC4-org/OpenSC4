extends Node

var INILoader = load("res://INILoader.gd")
var DBPF = load("res://DBPF.gd")

# Read the INI file
var INI_location = "./Apps/SimCity 4.ini"

func _init():
	# Read the INI file
	var ini_file = INILoader.new(INI_location)
	# Open the .dat files
	var dir = Directory.new()
	var err = dir.open(".")
	var dat_files = []
	if err != OK:
		print("Error opening directory")
		return
	dir.list_dir_begin()	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".dat"):
			dat_files.append(file)
	dir.list_dir_end()	
	for f in dat_files:
		print("Loading " + f)
		var dbpf = DBPF.new()
