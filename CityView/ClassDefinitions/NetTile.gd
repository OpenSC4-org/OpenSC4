class_name NetTile

var locations : Vector2
var edges : Array
var tile : TransitTile
var face_normal : Vector3

func _init(location_, edges_, tile_, face_normal_):
	self.locations = location_
	self.edges = edges_
	self.tile = tile_
	self.face_normal = face_normal_

