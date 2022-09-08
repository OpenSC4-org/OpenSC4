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
var drag_tracker : Array = []
var built_tracker : Array = []
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
									if layer_arr.has(line[2]):
										layer_inds[line[1]] = layer_arr.find(line[2])
							self.transit_tiles[t_type][w][n][e][s].append(TransitTile.new(rul_edges, rul_ids, layer_inds))
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
	self.add_child(drag_meshinst)
	#self.mat.set_shader_param("built", false)
	drag_meshinst.set_material_override(mat)
	#self.mat.set_shader_param("built", true)
	self.set_material_override(mat)
	
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == 1:
				self.start_l = self.mouse_ray()
		if not event.is_pressed():
			if event.button_index == 1 and self.hold_l:
				_build_network()
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
	self.drag_arrays.resize(ArrayMesh.ARRAY_MAX)
	self.drag_arrays[ArrayMesh.ARRAY_VERTEX] = []
	self.drag_arrays[ArrayMesh.ARRAY_NORMAL] = [] 
	self.drag_arrays[ArrayMesh.ARRAY_COLOR] = [] 
	self.drag_arrays[ArrayMesh.ARRAY_TEX_UV] = [] 
	self.drag_arrays[ArrayMesh.ARRAY_TEX_UV2] = [] 
	drag_tracker = []
	var heightmap = self.get_parent().get_node("Terrain").heightmap
	if len(layer_map) == 0:
		self.map_width = len(heightmap[0])
		self.map_height = len(heightmap)
		for _y in range(map_height):
			for _x in range(map_width):
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
	var best_orth_ind = 0
	for ind in range(len(directions)):
		var curr_dot = drag_dir.dot(directions[ind])
		if curr_dot > best_dot and ind < 4:
			best_orth_ind = ind
		if curr_dot > best_dot:
			best_dot = curr_dot
			best_ind = ind
	var draw_dir = directions[best_ind]
	var edges : Dictionary
	if start == end:
		edges[[0,0,0,0]] = [start]
	elif best_ind < 4:
		edges = edges_ortho(start, end, draw_dir)
	elif best_ind < 8:
		edges = edges_diag(start, end, draw_dir)
	elif best_ind < 16:
		edges = edges_far2(start, end, draw_dir)
	elif abs(start.x-end.x) * abs(start.y-end.y) > 15:
		edges = edges_far3(start, end, draw_dir)
	else:
		draw_dir = directions[best_orth_ind]
		edges = edges_ortho(start, end, draw_dir)
	for edge_t in edges.keys():
		var key_set = transit_tiles[type].keys()
		var tile_arr = transit_tiles[type].duplicate(true)
		for i in range(len(edge_t)):
			var key_check = edge_t[i]
			if key_set.has(int(key_check)):
				if i < (len(edge_t) - 1):
					key_set = tile_arr[int(key_check)].keys()
				tile_arr = tile_arr[int(key_check)]
			else:
				tile_arr = []
				break
		if len(tile_arr) == 0:
			print("ERROR cannot find edge match:", edge_t)
		# setting UVs like this means I do it only for tiles/allignments that arn't defined yet
		if not tile_arr[0].UVs.keys().has([0, draw_dir]):
			tile_arr[0].set_UVs(0, draw_dir)
		for location in edges[edge_t]:
			if true:#len(tile_arr) == 1:
				# generate vertices, basically location+UV, what about height though? normals?
				var t_verts = PoolVector3Array([])
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
				if(draw_dir.x>0 and draw_dir.y>0) or (draw_dir.x<0 and draw_dir.y<0):
					vecadd = PoolVector2Array([
						corners[0],
						corners[3],
						corners[1],
						corners[3],
						corners[2],
						corners[1]
					])
				for i in range(len(vecadd)):
					var add = vecadd[i]
					var vec_two = location+add
					var height = heightmap[vec_two.y][vec_two.x]
					# to make height stuff not insane I use a 16units/tile scale that gets adjusted in the transform
					t_verts.append(Vector3(vec_two.x, height/16.0+0.05, vec_two.y))
					# store location in vertex tracker
					# the shape of drag_tracker should 1 on 1 match the mesh arrays
					self.drag_tracker.append(location)
					self.drag_arrays[ArrayMesh.ARRAY_VERTEX].append(Vector3(vec_two.x, height/16.0+0.05, vec_two.y))
				# add vertices, normals and UVs to mesh, TODO change terrain
				var v : Vector3 = t_verts[2] - t_verts[0]
				var u : Vector3 = t_verts[1] - t_verts[0]
				var normal1 : Vector3 = v.cross(u).normalized()
				v  = t_verts[5] - t_verts[3]
				u  = t_verts[4] - t_verts[3]
				var normal2 : Vector3 = v.cross(u).normalized()
				var normal = ((normal1+normal2)/2.0).normalized()
				if normal == Vector3(0.0, 0.0, 0.0):
					print("debug 0 length normal vec", normal1, normal2, normal)
				# generate network tile and store it in network_tiles
				var net_tile = NetTile.new(location, edge_t, tile_arr[0], normal)
				var layer = tile_arr[0].text_arr_layers[0]
				# UV2 is used as a variable per vertex and not used for shading, it sets texture array-layer instead
				var layr_l = 0xFF & layer
				var layr_a = (0xFF00 & layer)>>8
				#var layr_g = (0xFF0000 & layer)>>16
				#var layr_a = (0x0F000000 & layer)>>24
				var layer_vec = Vector2(layr_l, layr_a)
				self.drag_tiles[location] = net_tile
				# yellow transparent color for dragged network
				var col = Color(1.0, 1.0, 0.1, 0.7)
				self.drag_arrays[ArrayMesh.ARRAY_NORMAL].append_array([normal, normal, normal, normal, normal, normal])
				self.drag_arrays[ArrayMesh.ARRAY_COLOR].append_array([col, col, col, col, col, col])
				self.drag_arrays[ArrayMesh.ARRAY_TEX_UV].append_array(tile_arr[0].UVs[[0, draw_dir]])
				self.drag_arrays[ArrayMesh.ARRAY_TEX_UV2].append_array([layer_vec, layer_vec, layer_vec, layer_vec, layer_vec, layer_vec])
				
				
				
			else:
				print("TODO")
				# surrounding tiles both existing and temporary
				# find best match from options
				# generate network tile and store it in network_tiles
				# generate vertices, basically location+UV
				# add vertices and UVs to mesh
	if len(self.drag_arrays[ArrayMesh.ARRAY_VERTEX]) > 0:
		var drag_array_mesh = ArrayMesh.new()
		drag_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, get_mesh_arrays(self.drag_arrays))
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
	"TODO Register tiles to network_tiles and figure out how to copy PoolVector3Array"
	if len(self.drag_arrays[ArrayMesh.ARRAY_VERTEX]) > 0:
		var debug = false
		if self.mesh == null:
			self.mesh = ArrayMesh.new()
		if len(self.built_arrays) == 0:
			self.built_arrays = []
			self.built_arrays.resize(ArrayMesh.ARRAY_MAX)
		#for i in len(drag_arrays[ArrayMesh.ARRAY_VERTEX]):
		for i in len(self.drag_arrays):
			var built = Vector2(0, 128)
			if self.built_arrays[i] == null and not self.drag_arrays[i] == null:
				self.built_arrays[i] = []
			if not self.drag_arrays[i] == null:
				for j in range(0, len(self.drag_arrays[i]), 6):
					var found = self.built_tracker.find(self.drag_tracker[j])
					if found == -1:
						for k in range(6):
							if i == ArrayMesh.ARRAY_TEX_UV2:
								self.built_arrays[i].append(self.drag_arrays[i][j+k]+built)
							else:
								self.built_arrays[i].append(self.drag_arrays[i][j+k])
					else:
						for k in range(6):
							if i == ArrayMesh.ARRAY_TEX_UV2:
								self.built_arrays[i][found+k] = self.drag_arrays[i][j+k]+built
							else:
								self.built_arrays[i][found+k] = self.drag_arrays[i][j+k]
				
		if debug:
			print("after:", len(self.built_arrays[ArrayMesh.ARRAY_VERTEX]))
			print("debug in Meshes/TransitTiles func _build_network")
		self.mesh.surface_remove(0)
		self.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, get_mesh_arrays(self.built_arrays))
	self.drag_arrays = []
	self.get_child(0).mesh.surface_remove(0)
	for key in self.drag_tiles.keys():
		self.network_tiles[key] = drag_tiles[key]
	self.drag_tiles = {}
	for j in range(0, len(self.drag_tracker), 6):
		var found = self.built_tracker.find(self.drag_tracker[j])
		if found == -1:
			for k in range(6):
				self.built_tracker.append(self.drag_tracker[j+k])
		else:
			for k in range(6):
				self.built_tracker[found+k] = self.drag_tracker[j+k]

func get_mesh_arrays(arrays):
	var ret_array = []
	ret_array.resize(ArrayMesh.ARRAY_MAX)
	ret_array[ArrayMesh.ARRAY_VERTEX] = PoolVector3Array(arrays[ArrayMesh.ARRAY_VERTEX])
	ret_array[ArrayMesh.ARRAY_NORMAL] = PoolVector3Array(arrays[ArrayMesh.ARRAY_NORMAL])
	ret_array[ArrayMesh.ARRAY_COLOR] = PoolColorArray(arrays[ArrayMesh.ARRAY_COLOR])
	ret_array[ArrayMesh.ARRAY_TEX_UV] = PoolVector2Array(arrays[ArrayMesh.ARRAY_TEX_UV])
	ret_array[ArrayMesh.ARRAY_TEX_UV2] = PoolVector2Array(arrays[ArrayMesh.ARRAY_TEX_UV2])
	return ret_array

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
	var half_d = draw_dir/2
	var e_key = [2 * abs(floor(half_d.x)), 2 * abs(floor(half_d.y)), 2 * ceil(half_d.x), 2 * ceil(half_d.y)]
	if network_tiles.keys().has(curr_tile):
		var e_existing = network_tiles[curr_tile].edges
		for e_ind in range(len(e_existing)):
			# if one of them is 0 they override, if they are the same the also override
			if e_existing[e_ind] == 0:
				# if they are the same don't add
				e_existing[e_ind] += e_key[e_ind]
		e_key = e_existing.duplicate()
	ret_edges[e_key] = []
	ret_edges[e_key].append(curr_tile)
	curr_tile += draw_dir
	while (curr_tile.x * abs(draw_dir.x)) != end.x and (curr_tile.y * abs(draw_dir.y)) != end.y:
		# use edge values as keys, 2 means orthogonal edge
		e_key = [int(2*abs(draw_dir.x)), int(2*abs(draw_dir.y)), int(2*abs(draw_dir.x)), int(2*abs(draw_dir.y))]
		if network_tiles.keys().has(curr_tile):
			var e_existing = network_tiles[curr_tile].edges
			for e_ind in range(len(e_existing)):
				# if one of them is 0 they override, if they are the same the also override
				if e_existing[e_ind] == 0:
					# if they are the same don't add
					e_existing[e_ind] += e_key[e_ind]
			e_key = e_existing.duplicate()
		# add edge to dict if its not in there
		if not ret_edges.keys().has(e_key):
			ret_edges[e_key] = []
		ret_edges[e_key].append(curr_tile)
		# find best next tile
		curr_tile += draw_dir
	e_key = [2 * ceil(half_d.x), 2 * ceil(half_d.y), 2 * abs(floor(half_d.x)), 2 * abs(floor(half_d.y))]
	if network_tiles.keys().has(curr_tile):
		var e_existing = network_tiles[curr_tile].edges
		for e_ind in range(len(e_existing)):
			# if one of them is 0 they override, if they are the same the also override
			if e_existing[e_ind] == 0:
				# if they are the same don't add
				e_existing[e_ind] += e_key[e_ind]
		e_key = e_existing.duplicate()
	if not ret_edges.keys().has(e_key):
		ret_edges[e_key] = []
	ret_edges[e_key].append(curr_tile)
	return ret_edges
	
func edges_diag(start, end, draw_dir):
	#print("diag")
	# two ways to start:
	#	| /|	|  |
	#	|/ |	| /|
	#	|__|	|/_|

	# Vector2(.7, .7), 	->	[3, 0, 0, 1]	alt	[0, 1, 3, 0]	start[0, 0, 0, 1]	alt[0, 0, 3, 0]
	# Vector2(-.7, .7),	->	[0, 0, 1, 3]	alt	[1, 3, 0, 0]	start[0, 0, 0, 3]	alt[1, 0, 0, 0]
	# Vector2(-.7, -.7),->	[0, 1, 3, 0]	alt	[3, 0, 0, 1]	start[0, 1, 0, 0]	alt[3, 0, 0, 0]
	# Vector2(.7, -.7),	->	[1, 3, 0, 0]	alt	[0, 0, 1, 3]	start[0, 3, 0, 0]	alt[0, 0, 1, 0]
	# 1 = \ , 3 = /
	"TODO need to always split the quad-to-triangles with the diagonal perpendicular to the network"
	"TODO 2-lines"
	var curr_tile = start
	var ret_edges = {}
	var edges_sets = [[
		abs(ceil(draw_dir.x) * 			(1+2*ceil(draw_dir.y))), 
		abs(abs(floor(draw_dir.y)) * 	(1+2*ceil(draw_dir.x))), 
		abs(abs(floor(draw_dir.x)) * 	(1+2*abs(floor(draw_dir.y)))), 
		abs(ceil(draw_dir.y) * 			(1+2*abs(floor(draw_dir.x))))
	],[
		abs(abs(floor(draw_dir.x)) * 	(1+2*abs(floor(draw_dir.y)))), 
		abs(ceil(draw_dir.y) * 			(1+2*abs(floor(draw_dir.x)))), 
		abs(ceil(draw_dir.x) * 			(1+2*ceil(draw_dir.y))), 
		abs(abs(floor(draw_dir.y)) * 	(1+2*ceil(draw_dir.x)))
	]]
	var curr_edges_i = 0
	if abs((end - start).x) > abs((end - start).y):
		curr_edges_i = 1
		
	# handle start, it uses s_key because setting values to e_key were overriding things
	var s_key = [0,0,0,0]
	if curr_edges_i == 0:
		s_key[0] = 0
		s_key[1] = edges_sets[curr_edges_i][1]
		s_key[2] = 0
		s_key[3] = edges_sets[curr_edges_i][3]
	else:
		s_key[0] = edges_sets[curr_edges_i][0]
		s_key[1] = 0
		s_key[2] = edges_sets[curr_edges_i][2]
		s_key[3] = 0
	if network_tiles.keys().has(curr_tile):
		var s_existing = network_tiles[curr_tile].edges
		for e_ind in range(len(s_existing)):
			# if one of them is 0 they override, if they are the same the also override
			if s_existing[e_ind] == 0:
				# if they are the same don't add
				s_existing[e_ind] += s_key[e_ind]
		s_key = s_existing.duplicate()
	ret_edges[s_key] = []
	ret_edges[s_key].append(curr_tile)
	curr_tile += Vector2(round(draw_dir.x)*curr_edges_i, round(draw_dir.y)*(1-curr_edges_i))
	curr_edges_i = (curr_edges_i+1)%2
	
	# this iters the range, since for diagonals abs(x) == abs(y) these simple != checks work
	while curr_tile.x != end.x and curr_tile.y != end.y:
		var e_key = edges_sets[curr_edges_i]
		if network_tiles.keys().has(curr_tile):
			var e_existing = network_tiles[curr_tile].edges
			for e_ind in range(len(e_existing)):
				# if one of them is 0 they override, if they are the same the also override
				if e_existing[e_ind] == 0:
					# if they are the same don't add
					e_existing[e_ind] += e_key[e_ind]
			e_key = e_existing.duplicate()
		# add edge to dict if its not in there
		if not ret_edges.keys().has(e_key):
			ret_edges[e_key] = []
		ret_edges[e_key].append(curr_tile)
		curr_tile += Vector2(round(draw_dir.x)*curr_edges_i, round(draw_dir.y)*(1-curr_edges_i))
		# 2%2=0, 1%2=1 so this toggles between 0 and 0
		curr_edges_i = (curr_edges_i+1)%2
	
	# handle end, it uses s_key because setting values to e_key were overriding things
	var f_key = [0,0,0,0]
	if curr_edges_i == 1:
		f_key[0] = 0
		f_key[1] = edges_sets[curr_edges_i][1]
		f_key[2] = 0
		f_key[3] = edges_sets[curr_edges_i][3]
	else:
		f_key[0] = edges_sets[curr_edges_i][0]
		f_key[1] = 0
		f_key[2] = edges_sets[curr_edges_i][2]
		f_key[3] = 0
	if network_tiles.keys().has(curr_tile):
		var f_existing = network_tiles[curr_tile].edges
		for e_ind in range(len(f_existing)):
			# if one of them is 0 they override, if they are the same the also override
			if f_existing[e_ind] == 0:
				# if they are the same don't add
				f_existing[e_ind] += f_key[e_ind]
		f_key = f_existing.duplicate()
	if not ret_edges.keys().has(f_key):
		ret_edges[f_key] = []
	ret_edges[f_key].append(curr_tile)
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
	var goal = end.x
	var curr = curr_tile.x
	var x_first = true
	if round(abs(draw_dir.x)) == 0:
		goal = end.y
		curr = curr_tile.y
		x_first = false
	var e_key = edge_steps[3]
	if network_tiles.keys().has(curr_tile):
		var e_existing = network_tiles[curr_tile].edges
		for e_ind in range(len(e_existing)):
			# if one of them is 0 they override, if they are the same the also override
			if e_existing[e_ind] == 0:
				# if they are the same don't add
				e_existing[e_ind] += e_key[e_ind]
		e_key = e_existing.duplicate()
	ret_edges[e_key] = []
	ret_edges[e_key].append(curr_tile)
	curr_tile += tile_steps[step]
	while curr != goal:
		e_key = edge_steps[step]
		if abs(curr - goal) == 1:
			e_key = edge_steps[0]
			step = (step + (len(tile_steps)-1))%len(tile_steps)
		if network_tiles.keys().has(curr_tile):
			var e_existing = network_tiles[curr_tile].edges
			for e_ind in range(len(e_existing)):
				# if one of them is 0 they override, if they are the same the also override
				if e_existing[e_ind] == 0:
					# if they are the same don't add
					e_existing[e_ind] += e_key[e_ind]
			e_key = e_existing.duplicate()
		# add edge to dict if its not in there
		if not ret_edges.keys().has(e_key):
			ret_edges[e_key] = []
		ret_edges[e_key].append(curr_tile)
		curr_tile += tile_steps[step]
		step = (step + 1)%len(tile_steps)
		if x_first:
			curr = curr_tile.x
		else:
			curr = curr_tile.y
	e_key = edge_steps[2]
	if network_tiles.keys().has(curr_tile):
		var e_existing = network_tiles[curr_tile].edges
		for e_ind in range(len(e_existing)):
			# if one of them is 0 they override, if they are the same the also override
			if e_existing[e_ind] == 0:
				# if they are the same don't add
				e_existing[e_ind] += e_key[e_ind]
		e_key = e_existing.duplicate()
	if not ret_edges.keys().has(e_key):
		ret_edges[e_key] = []
	ret_edges[e_key].append(curr_tile)
	curr_tile += tile_steps[step]
	return ret_edges
	
func edges_far3(start, end, draw_dir):
	#print("far3")
	var curr_tile = start
	var ret_edges = {}
	var main_vec : Vector2
	var sec_vec : Vector2
	var starting = true
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
	var goal = end.x
	var curr = curr_tile.x
	var x_first = true
	if round(abs(draw_dir.x)) == 0:
		goal = end.y
		curr = curr_tile.y
		x_first = false
	var e_key = edge_steps[4]
	if network_tiles.keys().has(curr_tile):
		var e_existing = network_tiles[curr_tile].edges
		for e_ind in range(len(e_existing)):
			# if one of them is 0 they override, if they are the same the also override
			if e_existing[e_ind] == 0:
				# if they are the same don't add
				e_existing[e_ind] += e_key[e_ind]
		e_key = e_existing.duplicate()
	ret_edges[e_key] = []
	ret_edges[e_key].append(curr_tile)
	curr_tile += tile_steps[step]
	while curr != goal:
		e_key = edge_steps[step]
		if step == 1 and starting:
			e_key = edge_steps[3]
		elif step == 2 and starting:
			e_key = edge_steps[4]
			starting = false
		elif abs(curr - goal) < 7 and step == 5:
			e_key = edge_steps[3]
		elif abs(curr - goal) < 6 and step == 0:
			e_key = edge_steps[4]
		elif abs(curr - goal) < 3:
			e_key = edge_steps[0]
			step-=1
		if network_tiles.keys().has(curr_tile):
			var e_existing = network_tiles[curr_tile].edges
			for e_ind in range(len(e_existing)):
				# if one of them is 0 they override, if they are the same the also override
				if e_existing[e_ind] == 0:
					# if they are the same don't add
					e_existing[e_ind] += e_key[e_ind]
			e_key = e_existing.duplicate()
		# add edge to dict if its not in there
		if not ret_edges.keys().has(e_key):
			ret_edges[e_key] = []
		ret_edges[e_key].append(curr_tile)
		curr_tile += tile_steps[step]
		step = (step + 1)%len(tile_steps)
		if x_first:
			curr = curr_tile.x
		else:
			curr = curr_tile.y
	e_key = edge_steps[3]
	if network_tiles.keys().has(curr_tile):
		var e_existing = network_tiles[curr_tile].edges
		for e_ind in range(len(e_existing)):
			# if one of them is 0 they override, if they are the same the also override
			if e_existing[e_ind] == 0:
				# if they are the same don't add
					e_existing[e_ind] += e_key[e_ind]
		e_key = e_existing.duplicate()
	if not ret_edges.keys().has(e_key):
		ret_edges[e_key] = []
	ret_edges[e_key].append(curr_tile)
	return ret_edges
