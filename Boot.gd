extends Node

var INILoader = load("res://INILoader.gd")
var DBPFLoader = load("res://DBPFLoader.gd")
var SubfileTGI = load("res://SubfileTGI.gd")

# Read the INI file
var INI_location = "./Apps/SimCity 4.ini"

var simcity_dat_files = []
var sounds_file
var intro_file
var ep1_file 

func _init():
	# Read the INI file
	var _ini = INILoader.new(INI_location)
	# Open the .dat files
	for i in range(1,6):
		simcity_dat_files.append(DBPFLoader.new("SimCity_%d.dat" % i))
	for i in range(5):
		print(" === Simcity_%d.dat === " % [i+1])
		simcity_dat_files[i].dbg_subfile_types()
	# Get the sounds file
	sounds_file = DBPFLoader.new("Sound.dat")
	print("=== Sound.dat === ")
	sounds_file.dbg_subfile_types()
	ep1_file = DBPFLoader.new("EP1.dat")
	print("=== EP1.dat === ")
	ep1_file.dbg_subfile_types()
	intro_file = DBPFLoader.new("Intro.dat")
	print("=== Intro.dat === ")
	intro_file.dbg_subfile_types()
