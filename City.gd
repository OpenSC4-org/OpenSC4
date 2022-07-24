extends Spatial

var size_w : int = 4
var size_h : int = 4
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var savefile
var ind_layer
var width
var height
var layer_arr = []
const TILE_SIZE : int = 16
const WATER_HEIGHT : int = 250 / TILE_SIZE

func _ready():
	rng.randomize()
	savefile = Boot.current_city
	create_terrain()
	create_water_mesh()
	#set_view(1)
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
	width = size_w * 64 + 1
	height = size_h * 64 + 1
	self.layer_arr.resize(width)
	var row = []
	row.resize(height)
	for coll in range(len(self.layer_arr)):
		self.layer_arr[coll] = []
		for cell in range(len(self.layer_arr)):
			self.layer_arr[coll].append(null)
		
	terrain_info.set_dimensions(width, height)
	for i in range(width):
		heightmap.append([])
		for j in range(height):
			heightmap[i].append(terrain_info.get_altitude(i, j))
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
	var layers = []
	var normalz = []
	for vert in [v0, v1, v2, v3]:
		var res = coord_to_uv(vert.x, vert.y, vert.z)
		uvs.append(res[0])
		self.layer_arr[vert.z][vert.x] = res[1]
		if heightmap:
			var normal = PoolVector3Array([
				((v1 - v0).cross(v2 - v0) + (v3 - v2).cross(v0 - v2)).normalized()
				])
			normalz.append(get_normal(vert, heightmap))
		else:
			normalz.append(Vector3(0.0, 1.0, 0.0))
	
	var vertices = PoolVector3Array()
	var normals = PoolVector3Array()
	var UVs = PoolVector2Array()
	
	if min(normal1.y, normal2.y) >= min(normal3.y, normal4.y):
		vertices.append(v0)
		UVs.append(uvs[0])
		normals.append(normalz[0])
		vertices.append(v2)
		UVs.append(uvs[2])
		normals.append(normalz[2])
		vertices.append(v1)
		UVs.append(uvs[1])
		normals.append(normalz[1])
		vertices.append(v0)
		UVs.append(uvs[0])
		normals.append(normalz[0])
		vertices.append(v3)
		UVs.append(uvs[3])
		normals.append(normalz[3])
		vertices.append(v2)
		UVs.append(uvs[2])
		normals.append(normalz[2])
	else:
		vertices.append(v0)
		UVs.append(uvs[0])
		normals.append(normalz[0])
		vertices.append(v3)
		UVs.append(uvs[3])
		normals.append(normalz[3])
		vertices.append(v1)
		UVs.append(uvs[1])
		normals.append(normalz[1])
		vertices.append(v3)
		UVs.append(uvs[3])
		normals.append(normalz[3])
		vertices.append(v2)
		UVs.append(uvs[2])
		normals.append(normalz[2])
		vertices.append(v1)
		UVs.append(uvs[1])
		normals.append(normalz[1])

	return [vertices, normals, UVs]

func create_terrain():
	self.ind_layer = $Spatial/Terrain.load_textures_to_uv_dict()
	var vertices : PoolVector3Array = PoolVector3Array()
	var normals : PoolVector3Array = PoolVector3Array()
	var UVs : PoolVector2Array = PoolVector2Array()
	# Random heightmap (for now)
	var heightmap : Array
	if savefile != null:
		heightmap = load_city_terrain(savefile)
	else:
		heightmap = gen_random_terrain(size_w * 64 + 1, size_h * 64 + 1)
	var tiles_w = size_w * 64 + 1
	var tiles_h = size_h * 64 + 1
	
	var v1
	var v2
	var v3
	var v4
	# Top surface 
	for i in range(tiles_w - 1):
		for j in range(tiles_h - 1):
			v1 = Vector3(i,   heightmap[i  ][j  ] / TILE_SIZE, j  )
			v2 = Vector3(i,   heightmap[i  ][j+1] / TILE_SIZE, j+1)
			v3 = Vector3(i+1, heightmap[i+1][j+1] / TILE_SIZE, j+1)
			v4 = Vector3(i+1, heightmap[i+1][j  ] / TILE_SIZE, j  )
			var r = create_face(v1, v2, v3, v4, heightmap)
			vertices.append_array(r[0])
			normals.append_array(r[1])
			UVs.append_array(r[2])
	"""
	# Generate the borders
	for i in range(tiles_w - 1):
		# border with Z = 0
		v1 = Vector3(i, heightmap[i][0] / TILE_SIZE, 0)
		v2 = Vector3(i, 0, 0)
		v3 = Vector3(i+1, 0, 0)
		v4 = Vector3(i+1, heightmap[i+1][0] / TILE_SIZE, 0)
		var r = create_face(v3, v2, v1, v4, heightmap)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		UVs.append_array(r[2])
		# border with Z = tiles_h
		v1 = Vector3(i, 0, tiles_h-1)
		v2 = Vector3(i, heightmap[i][tiles_h-1] / TILE_SIZE, tiles_h-1)
		v3 = Vector3(i+1, heightmap[i+1][tiles_h-1] / TILE_SIZE, tiles_h-1)
		v4 = Vector3(i+1, 0, tiles_h-1)
		r = create_face(v1, v2, v3, v4, heightmap)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		UVs.append_array(r[2])

	for i in range(tiles_h - 1):
		# border with X = 0
		v1 = Vector3(0, 0, i)
		v2 = Vector3(0, 0, i+1)
		v3 = Vector3(0, heightmap[0][i+1] / TILE_SIZE, i+1)
		v4 = Vector3(0, heightmap[0][i] / TILE_SIZE, i)
		var r = create_face(v1, v2, v3, v4, heightmap)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		UVs.append_array(r[2])
		# border with X = tiles_w
		v1 = Vector3(tiles_w-1, heightmap[tiles_w-1][i] / TILE_SIZE, i)
		v2 = Vector3(tiles_w-1, heightmap[tiles_w-1][i+1] / TILE_SIZE, i+1)
		v3 = Vector3(tiles_w-1, 0, i+1)
		v4 = Vector3(tiles_w-1, 0, i)
		r = create_face(v1, v2, v3, v4, heightmap)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		UVs.append_array(r[2])"""

	var array_mesh : ArrayMesh = ArrayMesh.new()
	var arrays : Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals 
	arrays[ArrayMesh.ARRAY_TEX_UV] = UVs 
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$Spatial/Terrain.mesh = array_mesh
	
	var layer_img = Image.new()
	var layer_flat = PoolByteArray([])
	for row in self.layer_arr:
		layer_flat.append_array(row)
	layer_img.create_from_data(width, height, false, Image.FORMAT_R8, layer_flat)
	var layer_tex = ImageTexture.new()
	layer_tex.create_from_image(layer_img, 2) 
	var mat = $Spatial/Terrain.get_material_override()
	mat.set_shader_param("layer", layer_tex)
	$Spatial/Terrain.set_material_override(mat)
	print("Terrain vertices: %d" % vertices.size())

func create_water_mesh():
	var vertices : PoolVector3Array = PoolVector3Array()
	var normals : PoolVector3Array = PoolVector3Array()
	var v1 = Vector3(0, WATER_HEIGHT, 0)
	var v2 = Vector3(0, WATER_HEIGHT, size_h * 64)
	var v3 = Vector3(size_w * 64, WATER_HEIGHT, size_h * 64)
	var v4 = Vector3(size_w * 64, WATER_HEIGHT, 0)
	var r = create_face(v1, v2, v3, v4, null)
	vertices.append_array(r[0])
	normals.append_array(r[1])

	var array_mesh : ArrayMesh = ArrayMesh.new()
	var arrays : Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$Spatial/WaterPlane.mesh = array_mesh
"""
func set_view(zoom):
	var values = [[[29.919, 74.68, 26.682], [-(90-51.931), -72.579, 4.64], [1.0, 1.0, 1.0]],
				[[29.919, 74.68, 26.682], [-(90-51.931), -72.579, 4.64], [1.0, 1.0, 1.0]],
				[[26.51, 66.452, 40.662], [-(90-51.768), -73.006, 6.503], [.999, .996, .996]],
				[[22.649, 57.13, 53.812], [-(90-51.517), -73.471, 8.804], [.997, .99, .989]],
				[[18.364, 46.784, 66.033], [-51.26, -74.112, 11.469], [.997, .983, .98]],
				[[18.364, 46.784, 66.033], [-30.26, -73.112, 11.0], [.997, .983, .98]]]
	var value = values[zoom-1]
	var trans = transform
	trans.basis.x =  transform.basis.x
	trans.basis.y =  transform.basis.y
	trans.basis.z =  transform.basis.z
	var r = 1.0
	trans = trans.rotated(Vector3(1.00, 0.00, 0.00), deg2rad(value[1][0]))
	trans = trans.rotated(Vector3(0.00, 1.00, 0.00), deg2rad(value[1][1]))
	trans = trans.rotated(Vector3(0.00, 0.00, 1.00), deg2rad(value[1][2]*1.5))
	trans = trans.scaled(Vector3(1.777778, 1.0, 1.0))
	#trans = trans.rotated(Vector3(0.00, 1.00, 0.00), r * 1.5707963268)
	#trans.origin = Vector3(-64.0, 200.0, -64.0)
	trans.origin = Vector3(value[0][0], value[0][1], value[0][2])
	#$KinematicBody/Camera.transform = trans
	$Sun.transform.origin = Vector3(-474, 575, -352)
	print($Sun.transform)
	$Sun.look_at(Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0))
	print($Sun.transform)
	
	var mat = $Terrain.get_material_override()
	mat.set_shader_param("zoom", zoom)
	$Terrain.set_material_override(mat)"""
	
func coord_to_uv(x, y, z):
	var TerrainTexTilingFactor = 0.2 # 0x6534284a,0x88cd66e9,0x00000001 describes this as 100m of terrain corresponds to this fraction of texture in farthest zoom
	var zoomTilingFactor = 160.0/float($KinematicBody.zoom_list[6-$KinematicBody.zoom])
	var x_factored = (float(x)*16.0/100.0) * TerrainTexTilingFactor * zoomTilingFactor
	var y_factored = (float(z)*16.0/100.0) * TerrainTexTilingFactor * zoomTilingFactor
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
	var vert_c = [[1.0, 1.0], [1.0, -1.0], [-1.0, -1.0], [-1.0, 1.0]]
	var vertices = []
	for coord in vert_c:
		vertices.append(
			Vector3(vert.x + coord[0], 
			(heightmap[vert.x + min(max(coord[0], min_x), max_x)][vert.z + min(max(coord[1], min_z), max_z)])/16.0, 
			vert.z + coord[1])
		)
	var s_normals = Vector3(0.0, 0.0, 0.0)
	for v_i in range(len(vertices)):
		var v1 = vert
		var v2 = vertices[v_i]
		var v3 = vertices[(v_i + 1)%(len(vertices)-1)]
		var v : Vector3 = v2 - v1
		var u : Vector3 = v3 - v1
		var normal : Vector3 = v.cross(u).normalized()
		s_normals = s_normals + normal
	var norm = (s_normals/len(vertices)).normalized()
	return norm
