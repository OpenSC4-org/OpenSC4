extends RefCounted

# See details: https://wiki.sc4devotion.com/index.php?title=DBDF

class_name DBDF #Database DirAccess Files

var entries = []

func load(file, location, size):
	file.seek(location)
	for _i in range(size / 16):
		entries.append(DBDFEntry.new(file))
