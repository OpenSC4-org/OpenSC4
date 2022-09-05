extends MeshInstance


var mat = self.get_material_override()
var textarr = false
var layer_arr : Array
var transit_tiles : Dictionary = {}
var network_tiles : Dictionary = {}
var network_graph : NetworkGraph
var drag_tiles : Dictionary = {}
var drag_arrays : Array = []
var built_arrays : Array = []
var drag_meshinst = MeshInstance.new()
var layer_map = []
var map_width : int
var map_height : int
#input
var start_l = false
var hold_l = false

# Called when the node enters the scene tree for the first time.
func _ready():
	"""
	- Load RUL's - done
	- Use RUL's to load FSH's into texarr and set layer_arr - done
	- Generate TransiTile objects - done
	"""
	var rul_iid_types = {
	0x0000001 : "Elevated Highway",
	0x0000002 : "Elevated Highway",
	0x0000003 : "WaterPipe",
	0x0000004 : "WaterPipe",
	0x0000005 : "Rail",
	0x0000006 : "Rail",
	0x0000007 : "Road",
	0x0000008 : "Road",
	0x0000009 : "Street",
	0x000000A : "Street",
	0x000000B : "Subway",
	0x000000C : "Subway",
	0x000000D : "Avenue",
	0x000000E : "Avenue",
	0x000000F : "Elevated Rail",
	0x0000010 : "Elevated Rail",
	0x0000011 : "One-Way Road",
	0x0000012 : "One-Way Road",
	0x0000013 : "Dirt Road",
	0x0000014 : "Dirt Road",
	0x0000015 : "Monorail",
	0x0000016 : "Monorail",
	0x0000017 : "Ground Highway",
	0x0000018 : "Ground Highway"}
	# it gets messy here, not sure how to make this not a tonne of loops without sacrificing fast lookups when drawing
	var tex_arr_layer_ind = 0
	# iter rul files
	for RUL_id in rul_iid_types.keys():
		var t_type = rul_iid_types[RUL_id]
		if not self.transit_tiles.keys().has(t_type):
			self.transit_tiles[t_type] = {}
		var rul_dict = Core.subfile(0x0a5bcf4b, 0xaa5bcf57, RUL_id, RULSubfile).RUL_wnes
		# iter options for west-edge
		#if t_type == "Road":
			#print("debug", rul_dict[0][2])
		for w in rul_dict.keys():
			if not self.transit_tiles[t_type].keys().has(w):
				self.transit_tiles[t_type][w] = {}
			# iter options for north-edge
			for n in rul_dict[w].keys():
				if not self.transit_tiles[t_type][w].keys().has(n):
					self.transit_tiles[t_type][w][n] = {}
				# iter options for east-edge
				for e in rul_dict[w][n].keys():
					if not self.transit_tiles[t_type][w][n].keys().has(e):
						self.transit_tiles[t_type][w][n][e] = {}
					# iter options for south-edge
					for s in rul_dict[w][n][e].keys():
						if not self.transit_tiles[t_type][w][n][e].keys().has(s):
							self.transit_tiles[t_type][w][n][e][s] = []
						# iter available alternatives for current 1-line
						for i in range(len(rul_dict[w][n][e][s])):
							var rul_edges = {0: [w, n, e, s]}
							var rul_ids = {}
							var uvs = {}
							var layer_inds = {}
							# iter its 2 and 3 lines
							for line in rul_dict[w][n][e][s][i]:
								# if 2-line it gets stored in edges
								if line[0] == 2:
									rul_edges[line[1]] = line.slice(2, 6)
								# else must be 3-line, add to rul_ids and initiate its FSH
								else:
									rul_ids[line[1]] = line.slice(2, 5)
									if not layer_arr.has(line[2]):
										# if matching FSH is found
										if Core.sub_by_type_and_group[[0x7ab50e44, 0x1abe787d]].keys().has(line[2]):
											layer_arr.append(line[2])
											tex_arr_layer_ind += 1
									var rot = line[3]
									var flip = line[4]
									uvs[line[1]] = get_uvs(rot, flip)
									if layer_arr.has(line[2]):
										layer_inds[line[1]] = layer_arr.find(line[2])
							self.transit_tiles[t_type][w][n][e][s].append(TransitTile.new(rul_edges, rul_ids, layer_inds, uvs))
	var format = false
	for i in range(len(layer_arr)):
		var iid = layer_arr[i]
		var t_FSH = Core.subfile(0x7ab50e44, 0x1abe787d, iid+4, FSHSubfile)
		if not format:
			format = t_FSH.img.get_format()
		if not self.textarr:
			self.textarr = TextureArray.new()
			self.textarr.create (
				t_FSH.width, 
				t_FSH.height, 
				len(layer_arr), 
				t_FSH.img.get_format(), 
				2
				)
		if format != t_FSH.img.get_format():
			print("TODO handle different formats, existing:", format, "\tnew:", t_FSH.img.get_format())
		else:
			textarr.set_layer_data(t_FSH.img, i)
	self.mat = self.get_material_override()
	self.mat.set_shader_param("textarr", textarr)
	self.set_material_override(mat)
	self.add_child(drag_meshinst)
	drag_meshinst.set_material_override(mat)
	
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == 1:
				self.start_l = self.mouse_ray()
		if not event.is_pressed():
			if event.button_index == 1:
				self.start_l = false
				self.hold_l = false
	if event is InputEventMouseMotion and start_l:
		self.hold_l = self.mouse_ray()
		self._drag_network(self.start_l, self.hold_l, "Road")

func mouse_ray():
	var ray_length = 2000
	var space = get_parent().get_world().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_tree().root.get_camera()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var ray_dict = space.intersect_ray(from, to)
	var ret_pos = Vector2()
	if ray_dict.keys().has("position"):
		var pos = ray_dict["position"]
		pos = self.get_parent().transform.affine_inverse().xform (pos)
		ret_pos = Vector2(floor(pos.x), floor(pos.z))
	return ret_pos
	
func _drag_network(start, end, type):
	if len(layer_map) == 0:
		var heightmap = self.get_parent().get_node("Terrain").heightmap
		self.map_width = len(heightmap[0])
		self.map_height = len(heightmap)
		for y in range(map_height):
			for x in range(map_width):
				layer_map.append(0)
				layer_map.append(0)
	var directions = [
		# ortho
		Vector2(1, 0), 
		Vector2(-1, 0), 
		Vector2(0, 1), 
		Vector2(0, -1),
		# diag
		Vector2(1, 1).normalized(), 
		Vector2(-1, 1).normalized(), 
		Vector2(-1, -1).normalized(), 
		Vector2(1, -1).normalized(),
		# FAR-2
		Vector2(1, 2).normalized(),
		Vector2(1, -2).normalized(),
		Vector2(-1, 2).normalized(),
		Vector2(-1, -2).normalized(),
		Vector2(2, 1).normalized(),
		Vector2(2, -1).normalized(),
		Vector2(-2, 1).normalized(),
		Vector2(-2, -1).normalized(),
		# FAR-3
		Vector2(1, 3).normalized(),
		Vector2(1, -3).normalized(),
		Vector2(-1, 3).normalized(),
		Vector2(-1, -3).normalized(),
		Vector2(3, 1).normalized(),
		Vector2(3, -1).normalized(),
		Vector2(-3, 1).normalized(),
		Vector2(-3, -1).normalized()
	]
	var drag_dir = (end - start).normalized()
	var best_ind = 0
	var best_dot = 0
	for ind in range(len(directions)):
		var curr_dot = drag_dir.dot(directions[ind])
		if curr_dot > best_dot:
			best_dot = curr_dot
			best_ind = ind
	var draw_dir = directions[best_ind]
	var edges : Dictionary
	if best_ind < 4:
		edges = edges_ortho(start, end, draw_dir)
	elif best_ind < 8:
		edges = edges_diag(start, end, draw_dir)
	elif best_ind < 16:
		edges = edges_far2(start, end, draw_dir)
	else:
		edges = edges_far3(start, end, draw_dir)
	var normals = PoolVector3Array([])
	var UVs = PoolVector2Array([])
	var UV2s = PoolVector2Array([])
	var vertices = PoolVector3Array([])
	var colors = PoolColorArray([])
	for edge_t in edges.keys():
		var key_set = transit_tiles[type].keys()
		var tile_arr = transit_tiles[type]
		for i in range(len(edge_t)):
			var key_check = edge_t[i]
			if key_set.has(int(key_check)):
				if i < (len(edge_t) - 2):
					key_set = tile_arr[int(key_check)].keys()
				tile_arr = tile_arr[int(key_check)]
			else:
				tile_arr = []
				break
		if len(tile_arr) == 0:
			print("ERROR cannot find edge match:", edge_t)
		for location in edges[edge_t]:
			if true:#len(tile_arr) == 1:
				# generate vertices, basically location+UV, what about height though? normals?
				var t_verts = PoolVector3Array([])
				var heightmap = self.get_parent().get_node("Terrain").heightmap
				# should use draw_dir's horizontal tangent to determine which direction needs to be flat
				# for diagonals that means slopechanges cause deviations
				var corners = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]
				var vecadd = PoolVector2Array([
					corners[0],
					corners[2],
					corners[1],
					corners[0],
					corners[3],
					corners[2]
					])
				for add in vecadd:
					var vec_two = location+add
					var height = heightmap[vec_two.y][vec_two.x]
					# to make height stuff not insane I use a 16units/tile scale that gets adjusted in the transform
					t_verts.append(Vector3(vec_two.x, height/16.0+0.05, vec_two.y))
				# add vertices, normals and UVs to mesh, TODO change terrain
				var v : Vector3 = t_verts[2] - t_verts[0]
				var u : Vector3 = t_verts[1] - t_verts[0]
				var normal : Vector3 = v.cross(u).normalized()
				v  = t_verts[3] - t_verts[0]
				u  = t_verts[2] - t_verts[0]
				normal = ((normal + v.cross(u).normalized())/2).normalized()
				# generate network tile and store it in network_tiles
				var net_tile = NetTile.new(location, edge_t, tile_arr[0], normal)
				var layer = tile_arr[0].text_arr_layers[0]
				# LA should allow for enough layers 
				var layr_l = 0xFF & layer
				var layr_a = (0xFF00 & layer)>>8
				#var layr_g = (0xFF0000 & layer)>>16
				#var layr_a = (0x0F000000 & layer)>>24
				var layer_vec = Vector2(layr_l, layr_a)
				UV2s.append_array([layer_vec, layer_vec, layer_vec, layer_vec, layer_vec, layer_vec])
				self.drag_tiles[location] = net_tile
				# yellow transparent color for dragged network
				var col = Color(1.0, 1.0, 0.0, 0.7)
				colors.append_array([col, col, col, col, col, col])
				# surface normal per tile
				normals.append_array([normal, normal, normal, normal, normal, normal])
				UVs.append_array(tile_arr[0].UVs[0])
				vertices.append_array(t_verts)
				
				
			else:
				print("TODO")
				# surrounding tiles both existing and temporary
				# find best match from options
				# generate network tile and store it in network_tiles
				# generate vertices, basically location+UV
				# add vertices and UVs to mesh
	#var layer_img = Image.new()
	#layer_img.create_from_data(self.map_width, self.map_height, false, Image.FORMAT_LA8, layer_map)
	#var layer_tex = ImageTexture.new()
	#layer_tex.create_from_image(layer_img, 2)
	#mat.set_shader_param("layer", layer_tex)
	#drag_meshinst.set_material_override(mat)
	if len(vertices) > 0:
		var drag_array_mesh = ArrayMesh.new()
		drag_arrays.resize(ArrayMesh.ARRAY_MAX)
		drag_arrays[ArrayMesh.ARRAY_VERTEX] = vertices
		drag_arrays[ArrayMesh.ARRAY_NORMAL] = normals 
		drag_arrays[ArrayMesh.ARRAY_COLOR] = colors 
		drag_arrays[ArrayMesh.ARRAY_TEX_UV] = UVs 
		drag_arrays[ArrayMesh.ARRAY_TEX_UV2] = UV2s 
		drag_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, drag_arrays)
		self.get_child(0).mesh = drag_array_mesh
	"""
	- determine direction - max(dot products of drag_dir and buildable dirs) - done
	- generate edge_values and fetch edge values from surrounding tiles
	- generate temp TransitTiles - done
	- draw temp TransitTiles - done?
	
	TODO
	- Implement 2-line checking
	"""
	
func _build_network():#start, end, type):
	"""
	- determine direction
	- generate edge_values and fetch edge values from surrounding tiles or use whatever drag calculated?
	- generate edge_values for existing tiles to be updated
	- fetch TransitTiles
	- add TransitTiles to mesh
	- update edges and nodes of the network graph
	"""
	pass
	
func get_uvs(rot : int, flip : int):
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
	return ret_uvs
	
func edges_ortho(start, end, draw_dir):
	#print("ortho")
	var curr_tile = start
	var ret_edges = {}
	while (curr_tile.x * abs(draw_dir.x)) != end.x and (curr_tile.y * abs(draw_dir.y)) != end.y:
		# use edge values as keys, 2 means orthogonal edge
		var e_key = [int(2*abs(draw_dir.x)), int(2*abs(draw_dir.y)), int(2*abs(draw_dir.x)), int(2*abs(draw_dir.y))]
		if network_tiles.keys().has(curr_tile):
			var e_existing = network_tiles[curr_tile].edges
			for e_ind in range(len(e_existing)):
				# if one of them is 0 they override, if they are the same the also override
				if e_existing[e_ind] * e_key[e_ind] == 0:
					# if they are the same don't add
					e_key[e_ind] += e_existing[e_ind]
		# add edge to dict if its not in there
		if not ret_edges.keys().has(e_key):
			ret_edges[e_key] = []
		ret_edges[e_key].append(curr_tile)
		# find best next tile
		curr_tile += draw_dir
	return ret_edges
	
func edges_diag(start, end, draw_dir):
	#print("diag")
	# two ways to start:
	#	| /|	|  |
	#	|/ |	| /|
	#	|__|	|/_|

	# Vector2(.7, .7), 	->	[3, 0, 0, 1]	alt	[0, 1, 3, 0]
	# Vector2(-.7, .7),	->	[0, 0, 1, 3]	alt	[1, 3, 0, 0]
	# Vector2(-.7, -.7),->	[0, 1, 3, 0]	alt	[3, 0, 0, 1]
	# Vector2(.7, -.7),	->	[1, 3, 0, 0]	alt	[0, 0, 1, 3]
	# 1 = \ , 3 = /
	"TODO need to always split the quad-to-triangles with the diagonal perpendicular to the network"
	"TODO 2-lines"
	var curr_tile = start
	var ret_edges = {}
	var edges_sets = [[
		ceil(draw_dir.x) * 			(1+2*ceil(draw_dir.y)), 
		abs(floor(draw_dir.y)) * 	(1+2*ceil(draw_dir.x)), 
		abs(floor(draw_dir.x)) * 	(1+2*abs(floor(draw_dir.y))), 
		ceil(draw_dir.y) * 			(1+2*abs(floor(draw_dir.x)))
	],[
		abs(floor(draw_dir.x)) * 	(1+2*abs(floor(draw_dir.y))), 
		ceil(draw_dir.y) * 			(1+2*abs(floor(draw_dir.x))), 
		ceil(draw_dir.x) * 			(1+2*ceil(draw_dir.y)), 
		abs(floor(draw_dir.y)) * 	(1+2*ceil(draw_dir.x))
	]]
	var curr_edges_i = 0
	if abs((end - start).x) > abs((end - start).y):
		curr_edges_i = 1
	while curr_tile.x != end.x and curr_tile.y != end.y:
		var e_key = edges_sets[curr_edges_i]
		if network_tiles.keys().has(curr_tile):
			var e_existing = network_tiles[curr_tile].edges
			for e_ind in range(len(e_existing)):
				# if one of them is 0 they override, if they are the same the also override
				if e_existing[e_ind] * e_key[e_ind] == 0:
					# if they are the same don't add
					e_key[e_ind] += e_existing[e_ind]
		# add edge to dict if its not in there
		if not ret_edges.keys().has(e_key):
			ret_edges[e_key] = []
		ret_edges[e_key].append(curr_tile)
		curr_tile += Vector2(round(draw_dir.x)*curr_edges_i, round(draw_dir.y)*(1-curr_edges_i))
		# 2%2=0, 1%2=1 so this toggles between 0 and 0
		curr_edges_i = (curr_edges_i+1)%2
	return ret_edges
	
func edges_far2(start, end, draw_dir):
	#print("far2")
	var curr_tile = start
	var ret_edges = {}
	var main_vec : Vector2
	var sec_vec : Vector2
	if abs(draw_dir.x) > abs(draw_dir.y):
		if draw_dir.x > 0:
			main_vec = Vector2(1, 0)
		else:
			main_vec = Vector2(-1, 0)
		if draw_dir.y > 0:
			sec_vec = Vector2(0, 1)
		else:
			sec_vec = Vector2(0, -1)
	else:
		if draw_dir.y > 0:
			main_vec = Vector2(0, 1)
		else:
			main_vec = Vector2(0, -1)
		if draw_dir.x > 0:
			sec_vec = Vector2(1, 0)
		else:
			sec_vec = Vector2(-1, 0)
	# starts with double straight step to assist the transition
	#          3->4
	#	        \\
	#    3->4->1->2
	#     \\
	# 0->1->2
	var tile_steps = [
		main_vec,
		main_vec,
		sec_vec-main_vec,
		main_vec,
	]
	var edge_steps = [
		[2*abs(main_vec.x), 	    2*abs(main_vec.y), 			2*abs(main_vec.x), 			2*abs(main_vec.y)],
		[2*abs(main_vec.x), 	    2*abs(main_vec.y), 			2*abs(main_vec.x), 			2*abs(main_vec.y)],
		# bottom two lines use min and max to convert pos/neg dir into 0 edges where needed
		[2*max(main_vec.x, 0), 	    2*max(main_vec.y,0), 		2*abs(min(main_vec.x, 0)), 	2*abs(min(main_vec.y, 0))],
		[2*abs(min(main_vec.x, 0)), 2*abs(min(main_vec.y, 0)), 	2*max(main_vec.x, 0), 		2*max(main_vec.y, 0)],
	]
	var step = 0
	while curr_tile.x != end.x and curr_tile.y != end.y:
		var e_key = edge_steps[step]
		if network_tiles.keys().has(curr_tile):
			var e_existing = network_tiles[curr_tile].edges
			for e_ind in range(len(e_existing)):
				# if one of them is 0 they override, if they are the same the also override
				if e_existing[e_ind] * e_key[e_ind] == 0:
					# if they are the same don't add
					e_key[e_ind] += e_existing[e_ind]
		# add edge to dict if its not in there
		if not ret_edges.keys().has(e_key):
			ret_edges[e_key] = []
		ret_edges[e_key].append(curr_tile)
		curr_tile += tile_steps[step]
		step = (step + 1)%len(tile_steps)
	return ret_edges
	
func edges_far3(start, end, draw_dir):
	#print("far3")
	var curr_tile = start
	var ret_edges = {}
	var main_vec : Vector2
	var sec_vec : Vector2
	if abs(draw_dir.x) > abs(draw_dir.y):
		if draw_dir.x > 0:
			main_vec = Vector2(1, 0)
		else:
			main_vec = Vector2(-1, 0)
		if draw_dir.y > 0:
			sec_vec = Vector2(0, 1)
		else:
			sec_vec = Vector2(0, -1)
	else:
		if draw_dir.y > 0:
			main_vec = Vector2(0, 1)
		else:
			main_vec = Vector2(0, -1)
		if draw_dir.x > 0:
			sec_vec = Vector2(1, 0)
		else:
			sec_vec = Vector2(-1, 0)
	# starts with double straight step to assist the transition
	#             4->5->6->7
	#	           \---\
	#    4->5->6->1->2->3
	#     \---\
	# 0->1->2->3
	var tile_steps = [
		main_vec,
		main_vec,
		main_vec,
		sec_vec-(main_vec*2),
		main_vec,
		main_vec,
	]
	var edge_steps = [
		[2*abs(main_vec.x), 	    2*abs(main_vec.y), 			2*abs(main_vec.x), 			2*abs(main_vec.y)],
		[2*abs(main_vec.x), 	    2*abs(main_vec.y), 			2*abs(main_vec.x), 			2*abs(main_vec.y)],
		[2*abs(main_vec.x), 	    2*abs(main_vec.y), 			2*abs(main_vec.x), 			2*abs(main_vec.y)],
		# bottom two lines use min and max to convert pos/neg dir into 0 edges where needed
		[2*max(main_vec.x, 0), 	    2*max(main_vec.y,0), 		2*abs(min(main_vec.x, 0)), 	2*abs(min(main_vec.y, 0))],
		[2*abs(min(main_vec.x, 0)), 2*abs(min(main_vec.y, 0)), 	2*max(main_vec.x, 0), 		2*max(main_vec.y, 0)],
		[2*abs(main_vec.x), 	    2*abs(main_vec.y), 			2*abs(main_vec.x), 			2*abs(main_vec.y)],
	]
	var step = 0
	while curr_tile.x != end.x and curr_tile.y != end.y:
		var e_key = edge_steps[step]
		if network_tiles.keys().has(curr_tile):
			var e_existing = network_tiles[curr_tile].edges
			for e_ind in range(len(e_existing)):
				# if one of them is 0 they override, if they are the same the also override
				if e_existing[e_ind] * e_key[e_ind] == 0:
					# if they are the same don't add
					e_key[e_ind] += e_existing[e_ind]
		# add edge to dict if its not in there
		if not ret_edges.keys().has(e_key):
			ret_edges[e_key] = []
		ret_edges[e_key].append(curr_tile)
		curr_tile += tile_steps[step]
		step = (step + 1)%len(tile_steps)
	return ret_edges
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
