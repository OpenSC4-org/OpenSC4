extends Node

class_name SubfileIndex

var type_id:int
var group_id:int
var instance_id:int
var location:int
var size:int
var dbpf

func _init(dbpf):
	type_id = dbpf.file.get_32()
	group_id = dbpf.file.get_32()
	instance_id = dbpf.file.get_32()
	location = dbpf.file.get_32()
	size = dbpf.file.get_32()
	self.dbpf = dbpf
