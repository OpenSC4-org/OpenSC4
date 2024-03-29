extends MeshInstance3D

var tmpMesh = ArrayMesh.new();
var vertices = PackedVector3Array()
var UVs = PackedVector2Array()
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
	# In Godot there can't be used ConfigFile initially
	# A custom parser has to be there
	# Then the ConfigFile is build
	var ini_str = file.raw_data.get_string_from_ascii()
	
	# Uncomment to see raw data in file - for debug purpose only
	#var file2 = File.new()
	#file2.open("user://terrain_params.ini", File.WRITE)
	#file2.store_string(ini_str)
	#file2.close()
	var configFile = ConfigFile.new()
	var current_section = ''
	for line in ini_str.split('\n'):
		line = line.strip_edges(true, true)
		if line.length() == 0:
			continue
		if line[0] == '#' or line[0] == ';':
			continue
		if line[0] == '[':
			current_section = line.substr(1, line.length() - 2)
		else:
			var key = line.split('=')[0]
			var value = line.split('=')[1]
			configFile.set_value(current_section,key,value)
	return configFile

func remove_comma_at_end_of_line(line):
	line = line.left(line.length() - 1)
	return line
	
func read_textures_numbers_and_build_tm_table(config):
	tm_table = []
	var textures = [17, 16, 21]
	
	var keys = config.get_section_keys("TropicalMiscTextures")
	for key in keys:
		if key == "LowCliff" or key == "Beach":
			textures.append(config.get_value("TropicalMiscTextures", key).hex_to_int())

	keys = config.get_section_keys("TropicalTextureMapTable")
	for key in keys:
		var value = config.get_value("TropicalTextureMapTable", key)
		value = remove_comma_at_end_of_line(value)
		var numbers = value.split(",")
		var list_of_numbers = []
		for number in numbers:
			number = number.hex_to_int()
			list_of_numbers.append(number)
			if not textures.has(number):
				textures.append(number)
		tm_table.append(list_of_numbers)
	return textures
	
	
func build_image_dict_and_texture_array(textures):
	# This function will create a dictionary with images(textures) and	
	var type_tex = 0x7ab50e44
	var group_tex = 0x891B0E1A
	var images_dict = {}
	var max_width = 0
	var height = 0
	var list_texture_format = []
	for texture in textures:
		for zoom in range(5):
			# Why such a calculation?
			var zoom_id = texture + (zoom  * 256)
			var fsh_subfile = Core.subfile(type_tex, group_tex, zoom_id, FSHSubfile)
			# Check the length of data
			if len(fsh_subfile.img.data["data"]) == 0:
				Logger.error("Invalid SFH")
			# Add the texture format to the list if is not yet there
			var texture_format = fsh_subfile.img.get_format()
			if not list_texture_format.has(texture_format):
				list_texture_format.append(texture_format)
			# Add the image to the dict based on zoom_id
			images_dict[zoom_id] = fsh_subfile
			# Search for the most wide texture and save also its height
			if fsh_subfile.width > max_width:
				max_width = fsh_subfile.width
				height = fsh_subfile.height
	
	var texture_array = Texture2DArray.new()
	texture_array.create (max_width, height, len(textures) * 5, list_texture_format[0], 2)
	return {
		"texture_array":texture_array,
		"images_dict": images_dict
	}
	
func create_ind_to_layer(config, images_dict, texture_array):	
	var dict = {}
	var layer = 0
	var cliff_index = config.get_value("TropicalMiscTextures", "LowCliff").hex_to_int()
	var beach_index = config.get_value("TropicalMiscTextures", "Beach").hex_to_int()	
	var top_edge
	var mid_edge
	var bot_edge
	
	for key in images_dict:
		var image = images_dict[key].img
		texture_array.set_layer_data(image, layer)
		if key < 256:
			dict[key] = layer
			if key == cliff_index:
				cliff_index = layer
			elif key == beach_index:
				beach_index = layer
			elif key == 17:
				top_edge = layer
			elif key == 16:
				mid_edge = layer
			elif key == 21:
				bot_edge = layer
		var test = texture_array.get_layer_data(layer)
		if len(test.data["data"]) == 0:
			Logger.error("failed to load layer %s with image %s" % [layer, key])
		layer += 1
	
	self.mat.set_shader_parameter("cliff_ind", float(cliff_index))
	self.mat.set_shader_parameter("beach_ind", float(beach_index))
	self.mat.set_shader_parameter("terrain", texture_array)
	self.set_material_override(self.mat)
	var mat_e = self.get_parent().get_node("Border").get_material_override()
	mat_e.set_shader_parameter("terrain", texture_array)
		
	mat_e.set_shader_parameter("top_ind", float(top_edge))
	mat_e.set_shader_parameter("mid_ind", float(mid_edge))
	mat_e.set_shader_parameter("bot_ind", float(bot_edge))
	
	return dict

func load_textures_to_uv_dict():
	# Output from this function is
	# tm_table
	# ind_to_layer - This is the UV dictionary?
	# mat
	# self
	
	# Load file from SubFile
	var type_ini = 0x00000000
	var group_ini = 0x8a5971c5
	var instance_ini = 0xAA597172
	var file = Core.subfile(type_ini, group_ini, instance_ini, DBPFSubfile)
	
	# File	- Read parameters related to the terrain
	var config = load_into_config_file(file)
	
	# See how the data actually looks like - comment next line of not DEBUG
	#config.save("user://new.ini")
	
	var textures = read_textures_numbers_and_build_tm_table(config)

	var results = build_image_dict_and_texture_array(textures)
		
	var ind_to_layer = create_ind_to_layer(config, results.images_dict, results.texture_array)
	
	#var f = File.new()
	#f.open("user://uv_dict.txt", File.WRITE)
	#f.store_line(to_json(ind_to_layer))
	#f.close()
	
	return ind_to_layer
	
func update_terrain(locations : PackedVector3Array, rot_flipped_UVs : PackedVector2Array):
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
