extends Node

class_name SubfileIndex

var type_id:int
var group_id:int
var instance_id:int
var location:int
var size:int
var dbpf

func _init(dbpf, buffer):
	type_id = buffer.get_u32()
	group_id = buffer.get_u32()
	instance_id = buffer.get_u32()
	location = buffer.get_u32()
	size = buffer.get_u32()
	self.dbpf = dbpf
