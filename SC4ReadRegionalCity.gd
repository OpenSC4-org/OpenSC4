extends DBPFSubfile
class_name SC4ReadRegionalCity

var version = [0,0]
var location = [0,0]
var size = [0,0]
var population_residential : int = 0
var population_commercial : int = 0
var population_industrial : int = 0
var mayor_rating : int = 0
var star_count : int = 0
var unknown = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var tutorial_flag : bool = false
var guid : int = 0
var mode : String = "god"

func _init(index).(index):
	pass

func load(file, dbdf=null):
	.load(file, dbdf)
	var stream = StreamPeerBuffer.new()
	stream.data_array = raw_data
	self.version = [stream.get_16(), stream.get_16()];
	self.location = [stream.get_32(), stream.get_32()];
	self.size = [stream.get_32(), stream.get_32()];
	self.population_residential = stream.get_32();
	self.population_commercial = stream.get_32();
	self.population_industrial = stream.get_32();
	stream.get_float();
	self.mayor_rating = stream.get_8()
	self.star_count = stream.get_8()
	self.tutorial_flag = stream.get_8() == 1
	self.guid = stream.get_32()
	self.unknown[5] = stream.get_32()
	self.unknown[6] = stream.get_32()
	self.unknown[7] = stream.get_32()
	self.unknown[8] = stream.get_32()
	self.unknown[9] = stream.get_32()
	var v = stream.get_8()
	if v == 0:
		self.mode = "god"
	elif v == 1:
		self.mode = "normal"

