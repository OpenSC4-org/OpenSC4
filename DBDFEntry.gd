extends Node

var type_id
var	group_id 
var instance_id
var final_size

func _init(file):
	self.type_id = file.get_32()
	self.group_id = file.get_32()
	self.instance_id = file.get_32()
	self.final_size = file.get_32()
