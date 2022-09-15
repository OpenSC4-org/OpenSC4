class_name NetTile

var locations : Vector2
var edges : Array
var tile : TransitTile
var draw_dir : Vector2

func _init(location_, edges_, tile_, draw_dir_):
	self.locations = location_
	self.edges = edges_
	self.tile = tile_
	self.draw_dir = draw_dir_

