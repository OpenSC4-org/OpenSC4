extends DBPFSubfile
class_name cSTETerrain__SaveAltitudes

var width : int
var height : int
var altitudes : Array

func _init(index).(index):
	pass

func load(file, dbpf=null):
	.load(file, dbpf)
	stream.data_array = raw_data
	var major = stream.get_16()
	print("major: %08x" % major)
	print("size: %d" % stream.get_size())
	for i in stream.get_size() / 4:
		altitudes.append(stream.get_float())

func set_dimensions(width_, height_):
	self.width = width_
	self.height = height_

func get_altitude(x, y):
	return altitudes[x * width + y]
