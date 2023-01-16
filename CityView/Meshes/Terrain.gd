extends MeshInstance

var tmpMesh = ArrayMesh.new();
var vertices = PoolVector3Array()
var UVs = PoolVector2Array()
var color = Color(0.9, 0.1, 0.1)
var mat = self.get_material_override()
var st = SurfaceTool.new()
var tm_table
var heightmap : Array

func _ready():
	#mat.albedo_color = color
	st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	for v in vertices.size(): 
		#st.add_color(color)
		st.add_uv(UVs[v])
		st.add_vertex(vertices[v])

	st.commit(tmpMesh)
	self.set_mesh(tmpMesh)

	
	
func load_into_config_file(file):	
	# In Godot there can't be used ConfigFile it results in error 43 (parse error)
	# It expect's values surounded by "" and they are not in DBPF file
	# so custom parse has to be there	
	var ini_str = file.raw_data.get_string_from_ascii()
	
	# Uncomment to see raw data in file - for debug purpose only
	#var file2 = File.new()
	#file2.open("user://terrain_params.ini", File.WRITE)
	#file2.store_string(ini_str)
	#file2.close()
	var configFile = ConfigFile.new()
	var dict = {}
	var current_section = ''
	for line in ini_str.split('\n'):
		line = line.strip_edges(true, true)
		if line.length() == 0:
			continue
		if line[0] == '#' or line[0] == ';':
			continue
		if line[0] == '[':
			current_section = line.substr(1, line.length() - 2)
			dict[current_section] = {}
		else:
			var key = line.split('=')[0]
			var value = line.split('=')[1]
			dict[current_section][key] = value
			configFile.set_value(current_section,key,value)
	return { "configFile": configFile, "dict": dict }

func remove_comma_at_end_of_line(line):
	line = line.left(line.length() - 1)
	return line
	
func load_textures_to_uv_dict():
	
	# Load file from SubFile
	var type_ini = 0x00000000
	var group_ini = 0x8a5971c5
	var instance_ini = 0xAA597172
	var file = Core.subfile(type_ini, group_ini, instance_ini, DBPFSubfile)
	
	# File	- Read parameters related to the terrain
	var json = load_into_config_file(file)
	var ini = json.dict
	var config = json.configFile
	# See how the data actually looks like
	config.save("user://new.ini")

	
	var textures = [17, 16, 21]
	var tm_dict = ini["TropicalTextureMapTable"]
	var cliff_index
	var beach_index
	var top_edge
	var mid_edge
	var bot_edge
	tm_table = []
	for line in ini["TropicalMiscTextures"].keys():
		if line == "LowCliff":
			textures.append((ini["TropicalMiscTextures"][line]).hex_to_int())
			cliff_index = (ini["TropicalMiscTextures"][line]).hex_to_int()
		elif line == "Beach":
			textures.append((ini["TropicalMiscTextures"][line]).hex_to_int())
			beach_index = (ini["TropicalMiscTextures"][line]).hex_to_int()
	for line in tm_dict.keys():
		var line_r = []
		for val_i in range(len(tm_dict[line].split(','))):
			var val = (tm_dict[line].split(',')[val_i]).hex_to_int()
			if val != 0: # space at end of line returned 0 value from hex_to_int
				line_r.append(val)
				if not textures.has(val):
					textures.append(val)
		tm_table.append(line_r)
	var type_tex = 0x7ab50e44
	var group_tex = 0x891B0E1A
	var img_dict = {}
	var width = 0
	var height = 0
	var formats = []
	var d_len = 0
	for instance in textures:
		while true: # set array index for textures to be used in shader
			var ind = tm_table.find(instance)
			if ind == -1:
				break
		for zoom in range(5):
			var inst_z = instance + (zoom * 256)
			var fsh_subfile = Core.subfile(
						type_tex, group_tex, inst_z, FSHSubfile
						)
			if not formats.has(fsh_subfile.img.get_format()):
				formats.append(fsh_subfile.img.get_format())
			var data_len = len(fsh_subfile.img.data["data"])
			if data_len > d_len:
				d_len = data_len
			if data_len == 0:
				print("error invalid FSH")
			if width < fsh_subfile.width:
				width = fsh_subfile.width
				height = fsh_subfile.height
			img_dict[inst_z] = fsh_subfile
	var textarr = TextureArray.new()
	textarr.create (width, height, len(textures) * 5, formats[0], 2)
	var layer = 0
	var ind_to_layer = {}
	for im_ind in img_dict.keys():
		var image = img_dict[im_ind].img
		textarr.set_layer_data(image, layer)
		if im_ind < 256:
			ind_to_layer[im_ind] = layer
			if im_ind == cliff_index:
				cliff_index = layer
			elif im_ind == beach_index:
				beach_index = layer
			elif im_ind == 17:
				top_edge = layer
			elif im_ind == 16:
				mid_edge = layer
			elif im_ind == 21:
				bot_edge = layer
		var test = textarr.get_layer_data(layer)
		if len(test.data["data"]) == 0:
			print("failed to load layer", layer, "with image", im_ind)
		layer += 1
	
	self.mat.set_shader_param("cliff_ind", float(cliff_index))
	self.mat.set_shader_param("beach_ind", float(beach_index))
	self.mat.set_shader_param("terrain", textarr)
	self.set_material_override(self.mat)
	var mat_e = self.get_parent().get_node("Border").get_material_override()
	mat_e.set_shader_param("terrain", textarr)
	mat_e.set_shader_param("top_ind", float(top_edge))
	mat_e.set_shader_param("mid_ind", float(mid_edge))
	mat_e.set_shader_param("bot_ind", float(bot_edge))
	return ind_to_layer
	
func update_terrain(locations : PoolVector3Array, rot_flipped_UVs : PoolVector2Array):
	var neighbours = [
		Vector3(-1, 0, -1),Vector3(0, 0, -1),Vector3(1, 0, -1),
		Vector3(-1, 0, 0),Vector3(0, 0, 0),Vector3(1, 0, 0),
		Vector3(-1, 0, 1),Vector3(0, 0, 1),Vector3(1, 0, 1)
		]
	var surface_ind = self.mesh.get_surface_count() - 1
	if surface_ind != 0:
		print("error: terrain somehow has more than one surface!")
	var arrays = self.mesh.surface_get_arrays(0).duplicate(true)
	self.mesh.surface_remove(0)
	var vertices_copy = arrays[ArrayMesh.ARRAY_VERTEX]
	var UVs_copy = arrays[ArrayMesh.ARRAY_TEX_UV]
	# iterate locations per quad
	var updated_vertices = []
	for i in range(0, len(locations), 6):
		var tile_loc = locations[i]
		for neigh in neighbours:
			var index = self.get_parent().get_parent().terr_tile_ind[Vector2(tile_loc.x+neigh.x, tile_loc.z+neigh.z)]
			# update vertices per quad
			for j in range(6):
				for k in range(6):
					if vertices_copy[index+j].x == locations[i+k].x and vertices_copy[index+j].z == locations[i+k].z:
						vertices_copy[index+j] = locations[i+k] - Vector3(0.0, 0.01, 0.0)
						# Vertex order can be different, therefore UVs needs updating
						if neigh == Vector3(0,0,0):
							UVs_copy[index+j] = rot_flipped_UVs[i+j]
				
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices_copy
	arrays[ArrayMesh.ARRAY_TEX_UV] = UVs_copy
	self.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
