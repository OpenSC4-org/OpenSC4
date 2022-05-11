extends Node

var INILoader = load("res://INILoader.gd")

# Read the INI file
var INI_location = "./Apps/SimCity 4.ini"

func _init():
	# Read the INI file
	var ini_file = INILoader.new(INI_location)

