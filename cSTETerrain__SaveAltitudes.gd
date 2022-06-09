extends DBPFSubfile
class_name cSTETerrain__SaveAltitudes

var width : int
var height : int
var altitudes : Array

func _init(index).(index):
	pass

func load(file, dbpf=null):
	.load(file, dbpf)
	var stream = StreamPeerBuffer.new()
	stream.data_array = raw_data
	var major = stream.get_16()
	print("major: %08x" % major)
	print("size: %d" % stream.get_size())
	for i in stream.get_size() / 4:
		altitudes.append(stream.get_float() / 100)

func set_dimensions(width, height):
	self.width = width
	self.height = height

func get_altitude(x, y):
	return altitudes[x * width + y]
