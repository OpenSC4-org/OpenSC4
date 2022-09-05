class_name TransitTile

var edges : Dictionary
var ids : Dictionary
var tilepaths : Dictionary
var text_arr_layers : Dictionary
var UVs : Dictionary

func _init(edges_ : Dictionary, ids_ : Dictionary, layers_ : Dictionary, uvs_ : Dictionary):
	self.edges = edges_
	self.ids = ids_
	self.tilepaths = self.set_tile_paths()
	self.text_arr_layers = layers_ #TODO Setup TextureArrays in a TransitMesh Use a layer dict to convert ID to TexArrLayer
	self.UVs = uvs_
	
	
func set_tile_paths():
	"""
	get path from SC4Path file (still needs parsing)
	"""
	return {}
