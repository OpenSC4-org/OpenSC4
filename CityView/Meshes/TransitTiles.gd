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
var drag_first = true
#input
var start_l = false
var hold_l = false
var drag_modes = {
	"Elevated Highway": 0x0011, "WaterPipe": 0x0011,"Rail":0x1111, 		"Road": 0x1111, 
	"Street":0x0001, 			"Subway":0x0011, 	"Avenue": 0x0011,	"Elevated Rail": 0x0011, 
	"One-Way Road": 0x1111, 	"Dirt Road":0x1111, "Monorail": 0x0011, "Ground Highway":0x0011
}
"""
11	12	13	14	15
10	2	3	4	16
9	1	0	5	17
24	8	7	6	18
23	22	21	20	19
"""
var neigh_num_to_vec = [
	# middle
	Vector2(0, 0),
	# inner ring
	Vector2(-1, 0),Vector2(-1, -1),Vector2(0, -1),Vector2(1, -1),
	Vector2(1, 0),Vector2(1, 1),Vector2(0, 1),Vector2(-1, 1),
	# outer ring
	Vector2(-2, 0),Vector2(-2, -1),Vector2(-2, -2),Vector2(-1, -2),
	Vector2(0, -2),Vector2(1, -2),Vector2(2, -2),Vector2(2, -1),
	Vector2(2, 0),Vector2(2, 1),Vector2(2, 2),Vector2(1, 2),
	Vector2(0, 2),Vector2(-1, 2),Vector2(-2, 2),Vector2(-2, 1)
]

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
	# iter rul files
	for RUL_id in rul_iid_types.keys():
		var t_type = rul_iid_types[RUL_id]
		if not self.transit_tiles.keys().has(t_type):
			self.transit_tiles[t_type] = {}
		var rul_dict = Core.subfile(0x0a5bcf4b, 0xaa5bcf57, RUL_id, RULSubfile).RUL_wnes
		# iter options for west-edge
		#if t_type == "Road":
			#print("debug", rul_dict[0][2])
		for wnes in rul_dict.keys():
			if not self.transit_tiles[t_type].keys().has(wnes):
				self.transit_tiles[t_type][wnes] = []
			for i in range(len(rul_dict[wnes])):
				var rul_edges = {0: wnes}
				var rul_ids = {}
				var layer_inds = {}
				# iter its 2 and 3 lines
				for line in rul_dict[wnes][i]:
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
						if layer_arr.has(line[2]):
							layer_inds[line[1]] = layer_arr.find(line[2])
				if wnes == [0,2,11,2]:
					print("debug")
				self.transit_tiles[t_type][wnes].append(TransitTile.new(rul_edges, rul_ids, layer_inds))
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
				self.hold_l = self.mouse_ray()
				self._drag_network(self.start_l, self.hold_l, "Road")
		if not event.is_pressed():
			if event.button_index == 1 and self.hold_l:
				_build_network()
				self.start_l = false
				self.hold_l = false
	elif event is InputEventMouseMotion and start_l:
		self.hold_l = self.mouse_ray()
		self._drag_network(self.start_l, self.hold_l, "Road")
	elif event is InputEventKey:
		if event.pressed and event.scancode == KEY_CONTROL:
			self.drag_first = not self.drag_first
			if self.start_l:
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
	self.drag_tiles = {}
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
	var edges : Array
	if start == end:
		edges = [[[0,0,0,0]],[start]]
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
	"""
	Allright, here I have the basic edges per location with edges[0] containing edges and edges[1] containing locations
	Now I need to interact this with existing tiles, for this I want two options, one with existing-first one with drag-first
	This would allow for a key-hold, for instance CRTL to set the mode to which edge is considered more important
	"""
	# combine edges with existing
	var intersect_ind = []
	for loc_i in range(len(edges[1])):
		var loc = edges[1][loc_i]
		if network_tiles.has(loc):
			var edge_d = edges[0][loc_i]
			var edge_e = network_tiles[loc].edges
			var edge_res = []
			if self.drag_first:
				for i in range(len(edge_d)):
					if edge_d[i] == 0:
						edge_res.append(edge_e[i])
					else:
						edge_res.append(edge_d[i])
			else:
				for i in range(len(edge_d)):
					if edge_e[i] == 0:
						edge_res.append(edge_d[i])
					else:
						edge_res.append(edge_e[i])
			var buff = edges[0].duplicate()
			buff[loc_i] = edge_res.duplicate()
			edges[0] = buff.duplicate()
			intersect_ind.append(loc_i)
			
	var neighbors = [Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0), Vector2(0, 1)]
	# iter over the intersection points
	for int_i in intersect_ind:
		var edge_base = edges[0][int_i].duplicate()
		# if intersection needs diagonals to be adjusted
		if not self.transit_tiles[type].has(edge_base):
			if edge_base == [2,0,1,0]:
				print("debug")
			var loc_to_fix = [edges[1][int_i]]
			var edge_ind_affected = []
			# while there is locations to fix, fix them
			while len(loc_to_fix) > 0:
				# get first in list and remove it from list
				var loc_fix = loc_to_fix[0]
				loc_to_fix.erase(loc_fix)
				# get the edge numbers
				var edge_fix
				if loc_fix in edges[1]:
					var ind = edges[1].find(loc_fix)
					edge_fix = edges[0][ind].duplicate()
				else:
					edge_fix = network_tiles[loc_fix].edges.duplicate()
				# edge_ind_affected starts with length 0
				if not len(edge_ind_affected) == 0:
					# get the first in list and remove it from list
					var edge_aff = edge_ind_affected[0]
					edge_ind_affected.erase(edge_aff)
					# update the affected edge
					if edge_fix[edge_aff] == 1 or edge_fix[edge_aff] == 3:
						edge_fix[edge_aff] += 10
						var affected_loc = neighbors[edge_aff] + loc_fix
						# calculate and add new affected edge values to the lists
						var n_i = (edge_aff+2)%4
						var n_edge 
						if edges[1].has(affected_loc):
							var n_ind = edges[1].find(affected_loc)
							n_edge = edges[0][n_ind]
						else:
							n_edge = network_tiles[affected_loc].edges
						# only add the neighbor if the affected edge wasn't fixed yet
						if n_edge[n_i] == 1 or n_edge[n_i] == 3:
							loc_to_fix.append(affected_loc)
							edge_ind_affected.append(n_i)
				# only do the below if the above did not produce a valid edge-set
				if not self.transit_tiles[type].has(edge_fix):
					var diag_inds = []
					# get the diagonals not yet changed, might need to change for rails as they have more edges
					for e in range(len(edge_fix)):
						if edge_fix[e] == 1 or edge_fix[e] == 3:
							diag_inds.append(e)
					# generate every combination of diagonal-edge-updates
					var options = []
					for i in range(len(diag_inds)):
						options.append([diag_inds[i]])
					for i in range(len(diag_inds)):
						for j in range(len(options)):
							if diag_inds[i] > options[j][0]:
								var option = options[j].duplicate()
								option.append(diag_inds[i])
								options.append(option.duplicate())
					# the above might not work, and was adding null values instead of edge combinations
					if options.has(null):
						print("debug")
					# go over the options
					for option in options:
						var edge_option = edge_fix.duplicate()
						# generate the change the option is set to make
						for i in range(len(option)):
							if edge_option[option[i]] == 1 or edge_option[option[i]] == 3:
								edge_option[option[i]] +=10
						# if option is valid
						if self.transit_tiles[type].has(edge_option):
							# go over the options changes and add affected neighbors
							for i in range(len(option)):
								var opt_i = option[i]
								var affected_loc = neighbors[opt_i] + loc_fix
								var n_i = (opt_i+2)%4
								var n_edge 
								if edges[1].has(affected_loc):
									var n_ind = edges[1].find(affected_loc)
									n_edge = edges[0][n_ind]
								else:
									n_edge = network_tiles[affected_loc].edges
								# only add the neighbor if the affected edge wasn't fixed yet
								if n_edge[n_i] == 1 or n_edge[n_i] == 3:
									loc_to_fix.append(affected_loc)
									edge_ind_affected.append(n_i)
							# check if the fixed tile is in edges(could be a built tile)
							if edges[1].has(loc_fix):
								var ind = edges[1].find(loc_fix)
								var edge_buff = edges[0].duplicate()
								edge_buff[ind] = edge_option.duplicate()
								edges[0] = edge_buff.duplicate()
							# if not yet in edges just add it as the build_network then overrides the existing tiles
							else:
								var edge_buff = edges[0].duplicate()
								edge_buff.append(edge_option.duplicate())
								edges[0] = edge_buff.duplicate()
								var loc_buff = edges[1].duplicate()
								loc_buff.append(loc_fix)
								edges[1] = loc_buff.duplicate()
							break
				else:
					if edges[1].has(loc_fix):
						var ind = edges[1].find(loc_fix)
						var edge_buff = edges[0].duplicate()
						edge_buff[ind] = edge_fix.duplicate()
						edges[0] = edge_buff.duplicate()
					# if not yet in edges just add it as the build_network then overrides the existing tiles
					else:
						var edge_buff = edges[0].duplicate()
						edge_buff.append(edge_fix.duplicate())
						edges[0] = edge_buff.duplicate()
						var loc_buff = edges[1].duplicate()
						loc_buff.append(loc_fix)
						edges[1] = loc_buff.duplicate()
					break
	"""
	Now that all edges are valid 
	I should go over the various options per location and find the tile that best fits the surroundings
	To do this I need a structure that translates the neighbour indicator in 2 and 3-lines into vectors
		neigh_num_to_vec does this ^^
	"""
	# check
	var tile_arr = []
	var overridden = []
	var overrider = []
	for i in range(len(edges[0])):
		var best_score = 0
		var best_points = 0
		var best_t_i = 0
		var b_loc = edges[1][i]
		var override = false
		for t_i in range(len(transit_tiles[type][edges[0][i]])):
			var points = 0
			var div = 0
			for line in transit_tiles[type][edges[0][i]][t_i].edges.keys():
				div += 1
				var vec = neigh_num_to_vec[line]
				var loc = b_loc + vec
				var drag_bool = edges[1].has(loc)
				var built_bool = network_tiles.has(loc)
				if drag_bool or built_bool:
					points += 1
			var score : float = float(points)/float(div)
			if (score > best_score) or (score == best_score and points > best_points):
				best_score = score
				best_points = points
				best_t_i = t_i
				if len(transit_tiles[type][edges[0][i]][t_i].ids) > 1:
					override = true
				else:
					override = false
		tile_arr.append(transit_tiles[type][edges[0][i]][best_t_i])
		if override and not b_loc in overridden:
			overrider.append(b_loc)
			for sub in transit_tiles[type][edges[0][i]][best_t_i].ids.keys():
				if sub != 0:
					var loc = b_loc + neigh_num_to_vec[sub]
					overridden.append(loc)
	"""
	now I need to generate normals, uvs, vertices, uv2-layer_indices and colors and add them to the arrays
	and generate and register the network tiles to drag_tiles
	
	first step is generate vertices and smoothen them
	"""
	# determine the edges that best match the perpendicular to the draw direction
	var best_perp
	var best_score_perp = 1
	for x in range(-1, 2):
		for y in range(-1, 2):
			var curr_vec = Vector2(x, y).normalized()
			if x != 0 or y != 0:
				var curr_score = abs(draw_dir.dot(curr_vec))
				if curr_score < best_score_perp:
					best_score_perp = curr_score
					best_perp = curr_vec
	var matches = []
	var first_step = null
	var last_step = null
	var step_length = 1
	# sqrt(2.0)/2.0 reasoning:
	#	x--x
	#	|\ |\
	#	| \| \
	#	x--x--x
	# sides are length 1, diagonal is sqrt(1^2 + 1^2) = sqrt(2)
	# distance between diagonals is half of that so sqrt(2.0)/2.0
	if best_perp.x == best_perp.y:
		step_length = sqrt(2.0)/2.0
		matches = [2,0]
		first_step = [3]
		last_step = [1]
		if draw_dir.x > 0:
			matches = [0,2]
			first_step = [1]
			last_step = [3]
	elif best_perp.x == -best_perp.y:
		step_length = sqrt(2.0)/2.0
		matches = [3,1]
		first_step = [0]
		last_step = [2]
		if draw_dir.x < 0:
			matches = [1,3] # to ensure counter-clockwise order
			first_step = [2]
			last_step = [0]
	elif best_perp.x != 0:
		first_step = [0,3]
		matches = [1,2]
		if draw_dir.y < 0:
			first_step = [2,1]
			matches = [3,0]
			
	else:
		first_step = [0,1]
		matches = [3,2]
		if draw_dir.x < 0:
			first_step = [2,3]
			matches = [1,0]
	# use the match
	var corners = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]
	var strip_heights = []
	if first_step != null:
		var height = 0
		for c_i in range(len(first_step)):
			var vec = edges[1][0] + corners[first_step[c_i]]
			height += heightmap[vec.y][vec.x]
		strip_heights.append(height/len(first_step))
	for loc_i in range(len(edges[1])):
		var height = 0
		for c_i in matches:
			var vec = edges[1][loc_i] + corners[c_i]
			height += heightmap[vec.y][vec.x]
		strip_heights.append(height/2.0)
	var height = 0
	if last_step != null:
		for c_i in range(len(last_step)): # need to use range(len()) because the array can be length 1 which godot derps on
			var vec = edges[1][-1] + corners[last_step[c_i]]
			height += heightmap[vec.y][vec.x]
		strip_heights.append(height/len(last_step))
	var MaxNetworkSlopeChange = 35.0 #degrees
	var MaxSlopeAlongNetwork = 35.0 #degrees
	var MaxNetworkHtAdjustment = 10.0/16.0
	var numSmoothingProgressionSteps = 2
	#var distAddedPerSmoothingProgressionStep = 4 # idk, i guess its supposed to take the average of more tiles?
	"""
	var max_height_change = tan(deg2rad(MaxSlopeAlongNetwork))*step_length
	var max_slope_change = tan(deg2rad(MaxNetworkSlopeChange))*step_length
	for _step in range(numSmoothingProgressionSteps):
		for h_i in range(len(strip_heights)):
			var from = strip_heights[max(h_i-1, 0)]
			var curr = strip_heights[h_i]
			var to = strip_heights[min(h_i+1, len(strip_heights)-1)]
			var slope = curr-to
			var change = abs((from-curr) - (curr-to))
			if abs(slope) > max_height_change or change > max_slope_change:
				var average = (from+curr+to)/3.0
				var step_height = 0.5 * (average-curr)
				curr += min(step_height, MaxNetworkHtAdjustment)
				strip_heights[h_i] = curr
	"""
	"""
	I should have smooth heights now, next is to turn them into vertices
	corner heights would be i, i+1, i+1, i+2 for diagonals
	"""
	# step_seq stores the index offset per corner-index
	var step_seq = {}
	var counter = 0
	if first_step != null:
		for step in range(len(first_step)):
			step_seq[first_step[step]] = counter
		counter += 1
	for step in matches:
		step_seq[step] = counter
	counter += 1
	if last_step != null:
		for step in range(len(last_step)):
			step_seq[last_step[step]] = counter
	var vecadd = [0,3,1,1,3,2]
	if(best_perp.x == -best_perp.y):
			vecadd = [1,0,2,2,0,3]
	#print(step_seq, draw_dir, best_perp)
	#print(strip_heights)
	var corner_uvs = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]
	# yellow transparent color for dragged network
	var col = Color(1.0, 1.0, 0.1, 0.7)
	for h_i in range(len(edges[1])):
		var tile = tile_arr[h_i]
		if not edges[1][h_i] in overridden:
			for sub_tile in tile.ids.keys():
				if tile.text_arr_layers.keys().has(sub_tile):
					var rot = tile.ids[sub_tile][1] # for multi-tile dragging there needs to be additional rot and flip added
					var flip = tile.ids[sub_tile][2] # since multi tile base-pieces presume we generate additional rot and flip
					var layer = tile.text_arr_layers[sub_tile] # TODO^^
					var layr_l = 0xFF & layer
					var layr_a = (0xFF00 & layer)>>8
					var layer_vec = Vector2(layr_l, layr_a)
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
					if edges[0][h_i] == [0,2,11,2] or edges[0][h_i] == [11,2,0,2]:
						print(overridden, edges[1][h_i], overrider)
						print(tile.ids[sub_tile], flip_uvs)
						print("debug")
					var normal_verts = []
					var sub_vec = edges[1][h_i] + neigh_num_to_vec[sub_tile]
					for vec_i in range(6):
						var vec = sub_vec + corners[vecadd[vec_i]]
						var vec_ht = strip_heights[h_i + step_seq[vecadd[vec_i]]]
						self.drag_arrays[ArrayMesh.ARRAY_VERTEX].append(Vector3(vec.x, vec_ht/16.0, vec.y))
						self.drag_arrays[ArrayMesh.ARRAY_TEX_UV].append(flip_uvs[vecadd[vec_i]])
						self.drag_arrays[ArrayMesh.ARRAY_COLOR].append(col)
						self.drag_arrays[ArrayMesh.ARRAY_TEX_UV2].append(layer_vec)
						self.drag_tracker.append(sub_vec)
						normal_verts.append(Vector3(vec.x, vec_ht/16.0, vec.y))
					# vecadd = [0,3,1,1,3,2] or [1,0,2,2,0,3]
					# indices   0 1 2 3 4 5		 0 1 2 3 4 5
					# ind 1 == 4 is used as the anchors
					# 2 to 0 and 5 to 3 results in counter-clockwise order for both
					var v = normal_verts[2] - normal_verts[1]
					var u = normal_verts[0] - normal_verts[1]
					var normal1 : Vector3 = v.cross(u).normalized()
					v  = normal_verts[5] - normal_verts[4]
					u  = normal_verts[3] - normal_verts[4]
					var normal2 : Vector3 = v.cross(u).normalized()
					for norm in [normal1, normal2]:
						for _face_vert in range(3):
							self.drag_arrays[ArrayMesh.ARRAY_NORMAL].append(norm)
		self.drag_tiles[edges[1][h_i]] = NetTile.new(edges[1][h_i], edges[0][h_i], tile, draw_dir)
	if len(self.drag_arrays[ArrayMesh.ARRAY_VERTEX]) > 0:
		var drag_array_mesh = ArrayMesh.new()
		drag_array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, get_mesh_arrays(self.drag_arrays))
		self.get_child(0).mesh = drag_array_mesh
	"""
	TODO 
	x diagonal intersections are bugged - done
	x situations where a neighbor is attempted to update into an imcompatible shape, should check the neighbors other diagonals before discaring
		and if another diagonal needs changing, it should do a recursion, so I should make a function that calls itself. - fixed
	- multi-tile networking
	- smoothening for built tiles - means smoothening should be 2-d
	  - need to lock the heights of intersections and direction changes? maybe the 2d height update is enough
	  - for tiles with locked perpendicularness I either need to add foundation or make the built one set the height for the drag
	  - the perpendicular flatness could be optional
	  - snapping to heights of parallel tiles could be optional
	  - could do three modes: BuiltFirst, DragFirst, Foundations where foundations makes it pick its own heights
	- transform terrain
	  - have the permanence of terrain transformation be optional
	  - add foundation logic: if delta_height > someval: do foundations
	x implement drag vs built prio toggle - done
	- Verticality and viaducts
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
		var built = Vector2(0, 128) # used to swap from yellow color to basic with tile colors
		var verts_to_terrain = PoolVector3Array(self.drag_arrays[ArrayMesh.ARRAY_VERTEX])
		var UVs_to_terrain = PoolVector2Array(self.drag_arrays[ArrayMesh.ARRAY_TEX_UV])
		self.get_parent().get_node("Terrain").update_terrain(verts_to_terrain, UVs_to_terrain)
		for i in len(self.drag_arrays):
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
		
		if self.mesh.get_surface_count() > 0:
			self.mesh.surface_remove(0)
		self.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, get_mesh_arrays(self.built_arrays))
	self.drag_arrays = []
	self.get_child(0).mesh.surface_remove(0)
	for key in self.drag_tiles.keys():
		self.network_tiles[key] = self.drag_tiles[key]
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
	
func edges_ortho(start: Vector2, end: Vector2, draw_dir: Vector2) -> Array:
	#print("ortho")
	var curr_tile = start
	var ret_edges = []
	var ret_locations = []
	var half_d = draw_dir/2
	var e_key = [int(2 * abs(floor(half_d.x))), int(2 * abs(floor(half_d.y))), int(2 * ceil(half_d.x)), int(2 * ceil(half_d.y))]
	ret_edges.append(e_key.duplicate())
	ret_locations.append(curr_tile)
	curr_tile += draw_dir
	while (curr_tile.x * abs(draw_dir.x)) != end.x and (curr_tile.y * abs(draw_dir.y)) != end.y:
		# use edge values as keys, 2 means orthogonal edge
		e_key = [int(2*abs(draw_dir.x)), int(2*abs(draw_dir.y)), int(2*abs(draw_dir.x)), int(2*abs(draw_dir.y))]
		# add edge to dict if its not in there
		ret_edges.append(e_key.duplicate())
		ret_locations.append(curr_tile)
		# find best next tile
		curr_tile += draw_dir
	e_key = [int(2 * ceil(half_d.x)), int(2 * ceil(half_d.y)), int(2 * abs(floor(half_d.x))), int(2 * abs(floor(half_d.y)))]
	ret_edges.append(e_key.duplicate())
	ret_locations.append(curr_tile)
	return [ret_edges, ret_locations]
	
func edges_diag(start: Vector2, end: Vector2, draw_dir: Vector2) -> Array:
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
	var curr_tile = start
	var ret_edges = []
	var ret_locations = []
	var edges_sets = [[
		int(abs(ceil(draw_dir.x) * 			(1+2*ceil(draw_dir.y)))), 
		int(abs(abs(floor(draw_dir.y)) * 	(1+2*ceil(draw_dir.x)))), 
		int(abs(abs(floor(draw_dir.x)) * 	(1+2*abs(floor(draw_dir.y))))), 
		int(abs(ceil(draw_dir.y) * 			(1+2*abs(floor(draw_dir.x)))))
	],[
		int(abs(abs(floor(draw_dir.x)) * 	(1+2*abs(floor(draw_dir.y))))), 
		int(abs(ceil(draw_dir.y) * 			(1+2*abs(floor(draw_dir.x))))), 
		int(abs(ceil(draw_dir.x) * 			(1+2*ceil(draw_dir.y)))), 
		int(abs(abs(floor(draw_dir.y)) * 	(1+2*ceil(draw_dir.x))))
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
	ret_edges.append(s_key.duplicate())
	ret_locations.append(curr_tile)
	curr_tile += Vector2(round(draw_dir.x)*curr_edges_i, round(draw_dir.y)*(1-curr_edges_i))
	curr_edges_i = (curr_edges_i+1)%2
	
	# this iters the range, since for diagonals abs(x) == abs(y) these simple != checks work
	while curr_tile.x != end.x and curr_tile.y != end.y:
		var e_key = edges_sets[curr_edges_i]
		# add edge to dict if its not in there
		ret_edges.append(e_key.duplicate())
		ret_locations.append(curr_tile)
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
	ret_edges.append(f_key.duplicate())
	ret_locations.append(curr_tile)
	return [ret_edges, ret_locations]
	
func edges_far2(start : Vector2, end : Vector2, draw_dir : Vector2) -> Array:
	#print("far2")
	var curr_tile = start
	var ret_edges = []
	var ret_locations = []
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
		[int(2*abs(main_vec.x)), 	    int(2*abs(main_vec.y)), 			int(2*abs(main_vec.x)), 			int(2*abs(main_vec.y))],
		[int(2*abs(main_vec.x)), 	    int(2*abs(main_vec.y)), 			int(2*abs(main_vec.x)), 			int(2*abs(main_vec.y))],
		# bottom two lines use min and max to convert pos/neg dir into 0 edges where needed
		[int(2*max(main_vec.x, 0)), 	int(2*max(main_vec.y,0)), 			int(2*abs(min(main_vec.x, 0))), 	int(2*abs(min(main_vec.y, 0)))],
		[int(2*abs(min(main_vec.x, 0))),int(2*abs(min(main_vec.y, 0))), 	int(2*max(main_vec.x, 0)), 			int(2*max(main_vec.y, 0))],
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
	ret_edges.append(e_key.duplicate())
	ret_locations.append(curr_tile)
	curr_tile += tile_steps[step]
	while curr != goal:
		e_key = edge_steps[step]
		if abs(curr - goal) == 1:
			e_key = edge_steps[0]
			step = (step + (len(tile_steps)-1))%len(tile_steps)
		# add edge to dict if its not in there
		ret_edges.append(e_key.duplicate())
		ret_locations.append(curr_tile)
		curr_tile += tile_steps[step]
		step = (step + 1)%len(tile_steps)
		if x_first:
			curr = curr_tile.x
		else:
			curr = curr_tile.y
	e_key = edge_steps[2]
	ret_edges.append(e_key.duplicate())
	ret_locations.append(curr_tile)
	curr_tile += tile_steps[step]
	return [ret_edges, ret_locations]
	
func edges_far3(start: Vector2, end: Vector2, draw_dir: Vector2) -> Array:
	#print("far3")
	var curr_tile = start
	var ret_edges = []
	var ret_locations = []
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
	
	#  = = = >
	#    < =
	var edge_steps = [
		[int(2*abs(main_vec.x)), 		int(2*abs(main_vec.y)), 		int(2*abs(main_vec.x)), 		int(2*abs(main_vec.y))],
		[int(2*abs(main_vec.x)), 		int(2*abs(main_vec.y)), 		int(2*abs(main_vec.x)), 		int(2*abs(main_vec.y))],
		[int(2*abs(main_vec.x)), 		int(2*abs(main_vec.y)), 		int(2*abs(main_vec.x)), 		int(2*abs(main_vec.y))],
		# bottom two lines use min and max to convert pos/neg dir into 0 edges where needed
		[int(2*max(main_vec.x, 0)), 	int(2*max(main_vec.y,0)), 		int(2*abs(min(main_vec.x, 0))), int(2*abs(min(main_vec.y, 0)))],
		[int(2*abs(min(main_vec.x, 0))),int(2*abs(min(main_vec.y, 0))), int(2*max(main_vec.x, 0)), 		int(2*max(main_vec.y, 0))],
		[int(2*abs(main_vec.x)), 		int(2*abs(main_vec.y)), 		int(2*abs(main_vec.x)), 		int(2*abs(main_vec.y))],
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
	ret_edges.append(e_key.duplicate())
	ret_locations.append(curr_tile)
	curr_tile += tile_steps[step]
	while curr != goal:
		e_key = edge_steps[step]
		# this if-elif chain makes the first and last segment have far-to-ortho transitions
		# might want to make this more flexible to incorporate more/all transitions
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
		# add edge to dict if its not in there
		ret_edges.append(e_key.duplicate())
		ret_locations.append(curr_tile)
		curr_tile += tile_steps[step]
		step = (step + 1)%len(tile_steps)
		if x_first:
			curr = curr_tile.x
		else:
			curr = curr_tile.y
	e_key = edge_steps[3]
	ret_edges.append(e_key.duplicate())
	ret_locations.append(curr_tile)
	return [ret_edges, ret_locations]
