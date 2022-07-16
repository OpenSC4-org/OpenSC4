extends Node

class_name FSH_Entry

var dir_tag
var entry_id
var	offset 
var size
var block_size
var width
var height
var x_coord
var y_coord
var x_pos
var y_pos
var mipmaps
var img

func _init(tag, offset):
	self.dir_tag = tag
	self.offset = offset
