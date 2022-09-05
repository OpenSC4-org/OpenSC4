class_name NetworkGraph

var edges : Dictionary = {}
var nodes : Array
var routes : Dictionary

func _init():
	pass

func _tiles_to_edges(tiles : Array):
	for tilepath in tiles[0].tilepaths:
		if not self.edges.keys().has(tilepath.type):
			self.edges[tilepath.type] = []
		var edge = NetGraphEdge.new()
		edge.start = tiles[0].location
		edge.end = tiles[-1].location
		for tile in tiles:
			edge.length += tilepath.length
			edge.tilelocations.append(tile.location)
			if not tile.networedges.keys().has(tilepath.type):
				tile.networedges[tilepath.type] = []
			tile.networkedges[tilepath.type].append(edge)
		self.edges[tilepath.type].append(edge)

