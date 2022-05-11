extends Node

var INILoader = load("res://INILoader.gd")
var DBPFLoader = load("res://DBPFLoader.gd")

# Read the INI file
var INI_location = "./Apps/SimCity 4.ini"

var simcity_dat_files = []
var sounds_file
var intro_file
var ep1_file 

func _init():
	# Read the INI file
	var ini_file = INILoader.new(INI_location)
	# Open the .dat files
	for i in range(1,5):
		simcity_dat_files.append(DBPFLoader.new("SimCity_%d.dat" % i))
	# Get the sounds file
	sounds_file = DBPFLoader.new("Sound.dat")
