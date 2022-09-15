class_name TransitTile

var edges : Dictionary
var ids : Dictionary
var tilepaths : Dictionary
var text_arr_layers : Dictionary
var UVs : Dictionary

func _init(edges_ : Dictionary, ids_ : Dictionary, layers_ : Dictionary):
	self.edges = edges_
	self.ids = ids_
	self.tilepaths = self.set_tile_paths()
	self.text_arr_layers = layers_

func set_UVs(tile_ind : int, dir : Vector2):
	var rot = self.ids[tile_ind][1]
	var flip = self.ids[tile_ind][2]
	"""
	rotations are declared as clockwise, godot requires counter-clockwise vertex declaration
	since flip->rotate =/= rotate->flip and rotations come first in the 3-line declaration
	  I will assume rotation is applied before flipping
	as flip is a bool that doesn't specify the axis to flip along I will assume it flips "horizontally" 
												along the v axis flipping the u coordinates ^^
	
	so a rotate=3, flip=1 would perform:
			rot		flip
		1-4		4-3		3-4
		| |  ->	| |  ->	| |
		2-3		1-2		2-1
	"""
	var corner_uvs = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]
	var rot_uvs = []
	for i in range(rot, 4+rot, 1):
		rot_uvs.append(corner_uvs[i%4])
	var flip_uvs = []
	if flip == 1:
		flip_uvs.append(rot_uvs[3])
		flip_uvs.append(rot_uvs[2])
		flip_uvs.append(rot_uvs[1])
		flip_uvs.append(rot_uvs[0])
	else:
		flip_uvs = rot_uvs
	# will need to use the same order when assigning vectors
	var ret_uvs = PoolVector2Array([
		flip_uvs[0],
		flip_uvs[2],
		flip_uvs[1],
		flip_uvs[0],
		flip_uvs[3],
		flip_uvs[2]
	])
	if (dir.x>0 and dir.y>0) or (dir.x<0 and dir.y<0):
		ret_uvs = PoolVector2Array([
			flip_uvs[0],
			flip_uvs[3],
			flip_uvs[1],
			flip_uvs[3],
			flip_uvs[2],
			flip_uvs[1]
		])
	self.UVs[[tile_ind, dir]] = ret_uvs
	
func set_tile_paths():
	"""
	get path from SC4Path file (still needs parsing)
	"""
	return {}
