extends Node

class_name SubfileIndex

var type_id:int
var group_id:int
var instance_id:int
var location:int
var size:int

func _init(file):
	type_id = file.get_32()
	group_id = file.get_32()
	instance_id = file.get_32()
	location = file.get_32()
	size = file.get_32()
