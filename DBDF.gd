extends Node

var entries = []
var DBDFEntry = load("res://DBDFEntry.gd")

func load(file, location, size):
	file.seek(location)
	for _i in range(size / 16):
		entries.append(DBDFEntry.new(file))
