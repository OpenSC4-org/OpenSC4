extends MeshInstance

var tmpMesh = ArrayMesh.new();
var vertices = PoolVector3Array()
var UVs = PoolVector2Array()
var color = Color(0.9, 0.1, 0.1)
var mat = self.get_material_override()
var st = SurfaceTool.new()
var tm_table

func _ready():

	vertices.push_back(Vector3(1,0,0))
	vertices.push_back(Vector3(1,0,1))
	vertices.push_back(Vector3(0,0,1))
	vertices.push_back(Vector3(0,0,0))

	UVs.push_back(Vector2(0,0))
	UVs.push_back(Vector2(0,1))
	UVs.push_back(Vector2(1,1))
	UVs.push_back(Vector2(1,0))

	#mat.albedo_color = color
	st.add_smooth_group(true)
	st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	for v in vertices.size(): 
		#st.add_color(color)
		st.add_uv(UVs[v])
		st.add_vertex(vertices[v])

	st.commit(tmpMesh)
	self.set_mesh(tmpMesh)

	
func load_textures_to_uv_dict():
	var type_ini = 0x00000000
	var group_ini = 0x8a5971c5
	var instance_ini = 0xAA597172
	var file = Boot.simcity_dat_1.get_subfile(type_ini, group_ini, instance_ini, DBPFSubfile)
	var ini_str = file.raw_data.get_string_from_ascii()
	var ini = {}
	var current_section = ''
	for line in ini_str.split('\n'):
		line = line.strip_edges(true, true)
		if line.length() == 0:
			continue
		if line[0] == '#' or line[0] == ';':
			continue
		if line[0] == '[':
			current_section = line.substr(1, line.length() - 2)
			ini[current_section] = {}
		else:
			var key = line.split('=')[0]
			var value = line.split('=')[1]
			ini[current_section][key] = value
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
	var i_hori = 0
	var i_vert = 0
	var width = 0
	var height = 0
	var formats = []
	var image_map = Image.new()
	var uv_dict = {}
	var d_len = 0
	for instance in textures:
		while true: # set array index for textures to be used in shader
			var ind = tm_table.find(instance)
			if ind == -1:
				break
		for zoom in range(5):
			var inst_z = instance + (zoom * 256)
			var fsh_subfile = Boot.simcity_dat_2.get_subfile(
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
	var w_size = int(16384 / width)
	var h_size = int(16384 / height)
	var tot_w
	var tot_h
	var format
	if len(formats) == 1:
		format = formats[0]
	else:
		print("TODO need to handle multiple formats")
	if len(textures) > w_size:
		tot_w = 16384
		tot_h = ceil(len(textures) / w_size) * 5 * height
	else:
		tot_w = len(textures) * width
		tot_h = 5 * height
	var uv_mipmap_offset = height / tot_h
	var arr_data = [PoolByteArray([])]
	while len(arr_data) < tot_h:
		arr_data.append_array(arr_data)
	arr_data = arr_data.slice(0, tot_h)
	"the data is read width first, so adding data horizontally is problematic"
	"I would need to go row by row and add the data corresponding to that row"
	"so I should keep a PoolByteArray per row, add padding where needed"
	"and append the rows together in the end"
	var format_decomp
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
		
		
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
