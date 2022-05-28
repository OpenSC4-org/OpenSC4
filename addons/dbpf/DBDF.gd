extends Reference

class_name DBDF

var entries = []

func load(file, location, size):
	file.seek(location)
	for _i in range(size / 16):
		entries.append(DBDFEntry.new(file))
