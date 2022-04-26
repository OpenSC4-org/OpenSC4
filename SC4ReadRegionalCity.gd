extends "res://SC4Subfile.gd"

var version = [0,0]
var location = [0,0]
var size = [0,0]
var population_residential = 0
var population_commercial = 0
var population_industrial = 0
var mayor_rating = 0

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
	self.mayor_rating = stream.get_8();
