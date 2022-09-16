extends Spatial

var size_w : int = 4
var size_h : int = 4
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var savefile
var width
var height
const TILE_SIZE : int = 16
const WATER_HEIGHT : float = 250.0 / TILE_SIZE
# stores where tiles are in the vertex, uv and normal arrays
var terr_tile_ind = {}
# translator from fsh-iid to texturearray layer
var ind_layer
# for cursor
var cur_img
var vec_hot

func _ready():
	rng.randomize()
	savefile = Boot.current_city
	create_terrain()
	set_cursor()
	pass

func gen_random_terrain(width : int, height : int) -> Array:
	var heightmap : Array = []
	var noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = 1
	noise.period = 20
	noise.persistence = 0.8
	for i in range(width):
		heightmap.append([])
		for j in range(height):
			var h = WATER_HEIGHT * TILE_SIZE + (noise.get_noise_2d(i, j) * 200 )
			heightmap[i].append(h)
	return heightmap

func load_city_terrain(svfile : DBPF):
	var heightmap : Array = []
	var city_info = svfile.get_subfile(0xca027edb, 0xca027ee1, 0, SC4ReadRegionalCity)
	var terrain_info = svfile.get_subfile(0xa9dd6ff4, 0xe98f9525, 00000001, cSTETerrain__SaveAltitudes)
	size_w = city_info.size[0]
	size_h = city_info.size[1]
	self.width = size_w * 64 + 1
	self.height = size_h * 64 + 1
		
	terrain_info.set_dimensions(self.width, self.height)
	for i in range(width):
		heightmap.append([])
		for j in range(self.height):
			heightmap[i].append(terrain_info.get_altitude(i, j))
	self.get_node("Spatial/Terrain").heightmap = heightmap
	return heightmap

#(0, 0)       (1, 0)
#	    0 - 3
#	    | \ |
#       1 - 2
#(0, 1)       (1, 1)
func create_face(v0 : Vector3, v1 : Vector3, v2 : Vector3, v3 : Vector3, heightmap):
	"""
	TODO:
		swap from surface normals to verex normals to make godot smoothen out edges
		
	"""
	var v : Vector3 = v1 - v0
	var u1 : Vector3 = v2 - v0
	var u2 : Vector3 = v3 - v1
	var w1 : Vector3 = v3 - v0
	var w2 : Vector3 = v3 - v2
	var normal1 : Vector3 = v.cross(u1).normalized()
	var normal2 : Vector3 = u1.cross(w1).normalized()
	var normal3 : Vector3 = v.cross(u2).normalized()
	var normal4 : Vector3 = u2.cross(w2).normalized()
	var uvs = []
	var normalz = []
	var layer_ind = []
	var layer_weights = []
	var vertex_layers = []
	var vertex_weights = []
	for i in range(4):
		var vert = [v0, v1, v2, v3][i]
		var res = coord_to_uv(vert.x, vert.y, vert.z)
		uvs.append(res[0])
		if heightmap:
			var weight = [0.0, 0.0, 0.0, 0.0]
			weight[i] = 1.0
			vertex_layers.append(res[1])
			vertex_weights.append([weight[0], weight[1], weight[2], weight[3]])
			normalz.append(get_normal(vert, heightmap))
		else:
			normalz.append(Vector3(0.0, 1.0, 0.0))
	
	var vertices = PoolVector3Array()
	var normals = PoolVector3Array()
	var UVs = PoolVector2Array()
	
	# this if-else is my attempt to make the terrain diagonals smart, sometimes they still don't cooperate
	if min(normal1.y, normal2.y) >= min(normal3.y, normal4.y):
		var uv2
		var cols = [null, null, null]
		if heightmap:
			uv2 = Vector2(vertex_layers[2]/255.0, vertex_layers[1]/255.0)
			cols = [
				Color(vertex_weights[0][0], vertex_weights[0][2], vertex_weights[0][1], vertex_layers[0]/255.0),
				Color(vertex_weights[2][0], vertex_weights[2][2], vertex_weights[2][1], vertex_layers[0]/255.0),
				Color(vertex_weights[1][0], vertex_weights[1][2], vertex_weights[1][1], vertex_layers[0]/255.0),
					]
		vertices.append(v0)
		UVs.append(uvs[0])
		normals.append(normalz[0])
		layer_ind.append(uv2)
		layer_weights.append(cols[0])
		vertices.append(v2)
		UVs.append(uvs[2])
		normals.append(normalz[2])
		layer_ind.append(uv2)
		layer_weights.append(cols[2])
		vertices.append(v1)
		UVs.append(uvs[1])
		normals.append(normalz[1])
		layer_ind.append(uv2)
		layer_weights.append(cols[1])
		
		if heightmap:
			uv2 = Vector2(vertex_layers[3]/255.0, vertex_layers[2]/255.0)
			cols = [
				Color(vertex_weights[0][0], vertex_weights[0][3], vertex_weights[0][2], vertex_layers[0]/255.0),
				Color(vertex_weights[3][0], vertex_weights[3][3], vertex_weights[3][2], vertex_layers[0]/255.0),
				Color(vertex_weights[2][0], vertex_weights[2][3], vertex_weights[2][2], vertex_layers[0]/255.0),
					]
		vertices.append(v0)
		UVs.append(uvs[0])
		normals.append(normalz[0])
		layer_ind.append(uv2)
		layer_weights.append(cols[0])
		vertices.append(v3)
		UVs.append(uvs[3])
		normals.append(normalz[3])
		layer_ind.append(uv2)
		layer_weights.append(cols[1])
		vertices.append(v2)
		UVs.append(uvs[2])
		normals.append(normalz[2])
		layer_ind.append(uv2)
		layer_weights.append(cols[2])
		
	else:
		var uv2
		var cols = [null, null, null]
		if heightmap:
			uv2 = Vector2(vertex_layers[3]/255.0, vertex_layers[1]/255.0)
			cols = [
				Color(vertex_weights[0][0], vertex_weights[0][3], vertex_weights[0][1], vertex_layers[0]/255.0),
				Color(vertex_weights[3][0], vertex_weights[3][3], vertex_weights[3][1], vertex_layers[0]/255.0),
				Color(vertex_weights[1][0], vertex_weights[1][3], vertex_weights[1][1], vertex_layers[0]/255.0),
					]
		vertices.append(v0)
		UVs.append(uvs[0])
		normals.append(normalz[0])
		layer_ind.append(uv2)
		layer_weights.append(cols[0])
		vertices.append(v3)
		UVs.append(uvs[3])
		normals.append(normalz[3])
		layer_ind.append(uv2)
		layer_weights.append(cols[1])
		vertices.append(v1)
		UVs.append(uvs[1])
		normals.append(normalz[1])
		layer_ind.append(uv2)
		layer_weights.append(cols[2])
		
		if heightmap:
			uv2 = Vector2(vertex_layers[2]/255.0, vertex_layers[1]/255.0)
			cols = [
				Color(vertex_weights[3][3], vertex_weights[3][2], vertex_weights[3][1], vertex_layers[3]/255.0),
				Color(vertex_weights[2][3], vertex_weights[2][2], vertex_weights[2][1], vertex_layers[3]/255.0),
				Color(vertex_weights[1][3], vertex_weights[1][2], vertex_weights[1][1], vertex_layers[3]/255.0),
					]
		vertices.append(v3)
		UVs.append(uvs[3])
		normals.append(normalz[3])
		layer_ind.append(uv2)
		layer_weights.append(cols[0])
		vertices.append(v2)
		UVs.append(uvs[2])
		normals.append(normalz[2])
		layer_ind.append(uv2)
		layer_weights.append(cols[1])
		vertices.append(v1)
		UVs.append(uvs[1])
		normals.append(normalz[1])
		layer_ind.append(uv2)
		layer_weights.append(cols[2])

	return [vertices, normals, UVs, layer_ind, layer_weights]

func create_edge(vert, n1, n2, normal):
	"""
	in: 4 vertices in array and two normals
	out: appropriate triangle vertices for 3 levels of edge depth 
		normals influence the thickness of the top two layers
		
	could i just do long quads and handle the rest in the fragment shader?
	how would the deterministic randomness be achieved? adding different phase and altitude sines?
	how would a fragment know its distance from the surface?
	can pass a Varying smooth y and a Varying static y from vertex to fragment,
	the difference will then indicate when to switch texture
	uv's will then just be in direct coordination to the height
	
	Static Noise texture (can also be used to spice up terrain randomness only needs to be set once)
	Long Quads -> Varying smooth and static -> uv.y's represent height, 
	should jiggle bottom uv.y's based on normal.y's
	"""
	var TerrainTexTilingFactor = 0.2
	var factor = (16.0/100.0) * TerrainTexTilingFactor
	var coords = [vert[0].x, vert[1].x, vert[2].x, vert[3].x]
	if abs(normal.x) < abs(normal.z):
		coords = [vert[0].z, vert[1].z, vert[2].z, vert[3].z]
	var uv0 = Vector2(float(coords[0]) * factor, 0.0)
	var uv1 = Vector2(float(coords[1]) * factor, 0.0)
	var uv2 = Vector2(float(coords[2]) * factor, vert[1].y * factor)
	var uv3 = Vector2(float(coords[3]) * factor, vert[0].y * factor)
	var vertices = []
	var normals = []
	var UVs = []
	vertices.append(vert[2])
	UVs.append(uv2)
	normals.append(normal)
	vertices.append(vert[1])
	UVs.append(uv1)
	normals.append(normal)
	vertices.append(vert[0])
	UVs.append(uv0)
	normals.append(normal)
	vertices.append(vert[3])
	UVs.append(uv3)
	normals.append(normal)
	vertices.append(vert[2])
	UVs.append(uv2)
	normals.append(normal)
	vertices.append(vert[0])
	UVs.append(uv0)
	normals.append(normal)
	return [vertices, normals, UVs]

func create_terrain():
	self.ind_layer = $Spatial/Terrain.load_textures_to_uv_dict()
	var vertices : PoolVector3Array = PoolVector3Array()
	var normals : PoolVector3Array = PoolVector3Array()
	var UVs : PoolVector2Array = PoolVector2Array()
	var col_layer_weights : PoolColorArray = PoolColorArray()
	var uv2_layer_ind : PoolVector2Array = PoolVector2Array()
	var e_vertices : PoolVector3Array = PoolVector3Array()
	var e_normals : PoolVector3Array = PoolVector3Array()
	var e_UVs : PoolVector2Array = PoolVector2Array()
	var w_vertices : PoolVector3Array = PoolVector3Array()
	var w_normals : PoolVector3Array = PoolVector3Array()
	var w_UVs : PoolVector2Array = PoolVector2Array()
	# Random heightmap (for now)
	var heightmap : Array
	if savefile != null:
		heightmap = load_city_terrain(savefile)
	else:
		heightmap = gen_random_terrain(size_w * 64 + 1, size_h * 64 + 1)
	$Spatial/WaterPlane.generate_wateredges(heightmap)
	var tiles_w = size_w * 64
	var tiles_h = size_h * 64
	
	var v1
	var v2
	var v3
	var v4
	var ve1
	var ve2
	var ve3
	var ve4
	var vw1
	var vw2
	var vw3
	var vw4
	var n_in1
	var n_in2
	# Top surface 
	for i in range(tiles_w):
		for j in range(tiles_h):
			v1 = Vector3(i,   heightmap[j  ][i  ] / TILE_SIZE, j  )
			v2 = Vector3(i,   heightmap[j+1][i  ] / TILE_SIZE, (j+1))
			v3 = Vector3((i+1), heightmap[j+1][i+1] / TILE_SIZE, (j+1))
			v4 = Vector3((i+1), heightmap[j  ][i+1] / TILE_SIZE, j  )
			var r = create_face(v1, v2, v3, v4, heightmap)
			terr_tile_ind[Vector2(v1.x, v1.z)] = len(vertices)
			vertices.append_array(r[0])
			normals.append_array(r[1])
			UVs.append_array(r[2])
			uv2_layer_ind.append_array(r[3])
			col_layer_weights.append_array(r[4])
			if i == 0:
				ve1 = v2
				ve2 = v1
				ve3 = Vector3(ve1.x, 0.0, ve2.z)
				ve4 = Vector3(ve2.x, 0.0, ve1.z)
				n_in1 = r[1][0]
				n_in2 = r[1][1]
				var e = create_edge([ve1, ve2, ve3, ve4], n_in1, n_in2, Vector3(0.0, 0.0, -1.0))
				e_vertices.append_array(e[0])
				e_normals.append_array(e[1])
				e_UVs.append_array(e[2])
			if i == tiles_w - 1:
				ve1 = v4
				ve2 = v3
				ve3 = Vector3(ve2.x, 0.0, ve2.z)
				ve4 = Vector3(ve1.x, 0.0, ve1.z)
				n_in1 = r[1][3]
				n_in2 = r[1][2]
				var e = create_edge([ve1, ve2, ve3, ve4], n_in1, n_in2, Vector3(0.0, 0.0, 1.0))
				e_vertices.append_array(e[0])
				e_normals.append_array(e[1])
				e_UVs.append_array(e[2])
			if j == 0:
				ve1 = v1
				ve2 = v4
				ve3 = Vector3(ve2.x, 0.0, ve2.z)
				ve4 = Vector3(ve1.x, 0.0, ve1.z)
				n_in1 = r[1][0]
				n_in2 = r[1][3]
				var e = create_edge([ve1, ve2, ve3, ve4], n_in1, n_in2, Vector3(1.0, 0.0, 0.0))
				e_vertices.append_array(e[0])
				e_normals.append_array(e[1])
				e_UVs.append_array(e[2])
			if j == tiles_h - 1:
				ve1 = v3
				ve2 = v2
				ve3 = Vector3(ve2.x, 0.0, ve2.z)
				ve4 = Vector3(ve1.x, 0.0, ve1.z)
				n_in1 = r[1][2]
				n_in2 = r[1][1]
				var e = create_edge([ve1, ve2, ve3, ve4], n_in1, n_in2, Vector3(-1.0, 0.0, 0.0))
				e_vertices.append_array(e[0])
				e_normals.append_array(e[1])
				e_UVs.append_array(e[2])
				
			vw1 = Vector3(i, WATER_HEIGHT, j)
			vw2 = Vector3(i, WATER_HEIGHT, j+1)
			vw3 = Vector3(i+1, WATER_HEIGHT, j+1)
			vw4 = Vector3(i+1, WATER_HEIGHT, j)
			var wa = create_face(vw1, vw2, vw3, vw4, null)
			w_vertices.append_array(wa[0])
			w_normals.append_array(wa[1])
			w_UVs.append_array(wa[2])

	var array_mesh : ArrayMesh = ArrayMesh.new()
	var arrays : Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals 
	arrays[ArrayMesh.ARRAY_TEX_UV] = UVs 
	arrays[ArrayMesh.ARRAY_TEX_UV2] = uv2_layer_ind
	arrays[ArrayMesh.ARRAY_COLOR] = col_layer_weights
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$Spatial/Terrain.mesh = array_mesh
	$Spatial/Terrain.create_trimesh_collision()
	
	#var layer_img = Image.new()
	#var layer_flat = PoolByteArray([])
	#for row in self.layer_arr:
	#	layer_flat.append_array(row)
	#layer_img.create_from_data(self.width, self.height, false, Image.FORMAT_R8, layer_flat)
	#var layer_tex = ImageTexture.new()
	#layer_tex.create_from_image(layer_img, 2) 
	#var mat = $Spatial/Terrain.get_material_override()
	#mat.set_shader_param("layer", layer_tex)
	#$Spatial/Terrain.set_material_override(mat)
	
	var e_rray_mesh : ArrayMesh = ArrayMesh.new()
	var e_rrays : Array = []
	e_rrays.resize(ArrayMesh.ARRAY_MAX)
	e_rrays[ArrayMesh.ARRAY_VERTEX] = e_vertices
	e_rrays[ArrayMesh.ARRAY_NORMAL] = e_normals 
	e_rrays[ArrayMesh.ARRAY_TEX_UV] = e_UVs 
	e_rray_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, e_rrays)
	$Spatial/Border.mesh = e_rray_mesh
	
	var warray_mesh : ArrayMesh = ArrayMesh.new()
	var warrays : Array = []
	warrays.resize(ArrayMesh.ARRAY_MAX)
	warrays[ArrayMesh.ARRAY_VERTEX] = w_vertices
	warrays[ArrayMesh.ARRAY_NORMAL] = w_normals 
	warrays[ArrayMesh.ARRAY_TEX_UV] = w_UVs 
	warray_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, warrays)
	$Spatial/WaterPlane.mesh = warray_mesh
	
	"test s3d"
	var TGI_s3d = {"T": 0x5ad0e817, "G": 0xbadb57f1, "I":0x16910410}
	var s3dobj = Core.subfile(TGI_s3d["T"], TGI_s3d["G"], TGI_s3d["I"], S3DSubfile)
	var location = Vector3(width/2, heightmap[int(width/2)][int(self.height/2)] / TILE_SIZE, self.height/2)
	s3dobj.add_to_mesh($Spatial/TestS3D, location)
	test_exemplar()
	var s3dmat = $Spatial/TestS3D.get_material_override()
	s3dmat.set_shader_param("nois_texture", $Spatial/WaterPlane/NoiseTexture.texture)
	$Spatial/TestS3D.set_material_override(s3dmat)
	print("DEBUG")
	
func set_cursor():
	var TGI_cur = {"T": 0xaa5c3144, "G": 0x00000032, "I":0x13b138d0}
	self.vec_hot = Core.subfile(TGI_cur["T"], TGI_cur["G"], TGI_cur["I"], CURSubfile).entries[0].vec_hotspot
	self.cur_img = Core.subfile(TGI_cur["T"], TGI_cur["G"], TGI_cur["I"], CURSubfile).get_as_texture()
	Input.set_custom_mouse_cursor(cur_img, Input.CURSOR_ARROW, vec_hot)
	
func coord_to_uv(x, y, z):
	var TerrainTexTilingFactor = 0.2 # 0x6534284a,0x88cd66e9,0x00000001 describes this as 100m of terrain corresponds to this fraction of texture in farthest zoom
	var x_factored = (float(x)*16.0/100.0) * TerrainTexTilingFactor
	var y_factored = (float(z)*16.0/100.0) * TerrainTexTilingFactor
	var temp = max(min(32-int((y-15.0) * 1.312), 31),0) # 0x6534284a,0x7a4a8458,0x1a2fdb6b describes AltitudeTemperatureFactor of 0.082, i multiplied this by 16
	
	var moist = 6
	var inst_key = $Spatial/Terrain.tm_table[temp][moist]
	return [Vector2(x_factored, y_factored), self.ind_layer[inst_key]]
	
func get_normal(vert : Vector3, heightmap):
	var min_x = 0.0
	if vert.x > 0:
		min_x = -1.0
	var max_x = 0.0
	if vert.x < (len(heightmap)-1):
		max_x = 1.0
	var min_z = 0.0
	if vert.z > 0:
		min_z = -1.0
	var max_z = 0.0
	if vert.z < (len(heightmap)-1):
		max_z = 1.0
	var vert_c = [[1.0, 0.0], [0.0, 1.0], [-1.0, 0.0], [0.0, -1.0]]
	var vertices = []
	for coord in vert_c:
		vertices.append(
			Vector3(vert.x + coord[0], 
			(heightmap[(vert.z) + min(max(coord[1], min_z), max_z)][(vert.x) + min(max(coord[0], min_x), max_x)])/16.0, 
			vert.z + coord[1])
		)
	var s_normals = Vector3(0.0, 0.0, 0.0)
	#print(vert, "\t", vertices)
	for v_i in range(len(vertices)):
		var v1 = vert
		var v2 = vertices[v_i]
		var v3 = vertices[(v_i - 1)%(len(vertices)-1)]
		var v : Vector3 = v2 - v1
		var u : Vector3 = v3 - v1
		var normal : Vector3 = v.cross(u).normalized()
		#var normal2 : Vector3 = u.cross(v)
		#print([v1, v2, v3], "\t", u, "\t", v, "\t", normal, "\t", normal2)
		s_normals = s_normals + normal
	var norm = (s_normals/len(vertices)).normalized()
	return norm
	
func test_exemplar():
	var TGI = {"T": 0x6534284a, "G": 0xea12f32c, "I": 0x5}
	var exemplar = Core.subfile(TGI["T"], TGI["G"], TGI["I"], ExemplarSubfile)
	print("ParentCohort", exemplar.parent_cohort)
	for key in exemplar.properties.keys():
		print(key, "\t", exemplar.key_description(key), "\t", exemplar.properties[key])
		
