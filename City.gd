extends Spatial

var size_w : int = 4
var size_h : int = 4
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var savefile
var uv_dict
const TILE_SIZE : int = 16
const WATER_HEIGHT : int = 250 / TILE_SIZE

func _ready():
	rng.randomize()
	savefile = Boot.current_city
	create_terrain()
	create_water_mesh()
	set_view(1)
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
	var width = size_w * 64 + 1
	var height = size_h * 64 + 1
	terrain_info.set_dimensions(width, height)
	for i in range(width):
		heightmap.append([])
		for j in range(height):
			heightmap[i].append(terrain_info.get_altitude(i, j))
	return heightmap

#(0, 0)       (1, 0)
#	    1 - 4
#	    | \ |
#       2 - 3
#(0, 1)       (1, 1)
func create_face(v1 : Vector3, v2 : Vector3, v3 : Vector3, v4 : Vector3):
	"""
	TODO:
		Pick diagonal based on least steepness
	"""
	var height = int((v1.y + v2.y+v3.y+v4.y)/4)
	var v : Vector3 = v2 - v1
	var u1 : Vector3 = v3 - v1
	var u2 : Vector3 = v4 - v2
	var w1 : Vector3 = v4 - v1
	var w2 : Vector3 = v4 - v3
	var normal1 : Vector3 = v.cross(u1).normalized()
	var normal2 : Vector3 = u1.cross(w1).normalized()
	var normal3 : Vector3 = v.cross(u2).normalized()
	var normal4 : Vector3 = u2.cross(w2).normalized()
	var uv_arr = height_to_uv(height, min(max(normal1.y, normal2.y), max(normal3.y, normal4.y)))
	print(uv_arr)
	var UV1 = uv_arr[0]
	var UV2 = uv_arr[1]
	var UV3 = uv_arr[2]
	var UV4 = uv_arr[3]
	
	var vertices = PoolVector3Array()
	var normals = PoolVector3Array()
	var UVs = PoolVector2Array()
	
	if min(normal1.y, normal2.y) >= min(normal3.y, normal4.y):
		vertices.append(v1)
		UVs.append(UV1)
		vertices.append(v3)
		UVs.append(UV3)
		vertices.append(v2)
		UVs.append(UV2)
		vertices.append(v1)
		UVs.append(UV1)
		vertices.append(v4)
		UVs.append(UV4)
		vertices.append(v3)
		UVs.append(UV3)
		for _k in range(3):
			normals.append(normal1)
		for _k in range(3):
			normals.append(normal2)
	else:
		vertices.append(v1)
		UVs.append(UV1)
		vertices.append(v4)
		UVs.append(UV4)
		vertices.append(v2)
		UVs.append(UV2)
		vertices.append(v4)
		UVs.append(UV4)
		vertices.append(v3)
		UVs.append(UV3)
		vertices.append(v2)
		UVs.append(UV2)
		for _k in range(3):
			normals.append(normal3)
		for _k in range(3):
			normals.append(normal4)

	return [vertices, normals, UVs]

func create_terrain():
	self.uv_dict = $Terrain.load_textures_to_uv_dict()
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
			var r = create_face(v1, v2, v3, v4)
			vertices.append_array(r[0])
			normals.append_array(r[1])
			UVs.append_array(r[2])

	# Generate the borders
	for i in range(tiles_w - 1):
		# border with Z = 0
		v1 = Vector3(i, heightmap[i][0] / TILE_SIZE, 0)
		v2 = Vector3(i, 0, 0)
		v3 = Vector3(i+1, 0, 0)
		v4 = Vector3(i+1, heightmap[i+1][0] / TILE_SIZE, 0)
		var r = create_face(v3, v2, v1, v4)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		UVs.append_array(r[2])
		# border with Z = tiles_h
		v1 = Vector3(i, 0, tiles_h-1)
		v2 = Vector3(i, heightmap[i][tiles_h-1] / TILE_SIZE, tiles_h-1)
		v3 = Vector3(i+1, heightmap[i+1][tiles_h-1] / TILE_SIZE, tiles_h-1)
		v4 = Vector3(i+1, 0, tiles_h-1)
		r = create_face(v1, v2, v3, v4)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		UVs.append_array(r[2])

	for i in range(tiles_h - 1):
		# border with X = 0
		v1 = Vector3(0, 0, i)
		v2 = Vector3(0, 0, i+1)
		v3 = Vector3(0, heightmap[0][i+1] / TILE_SIZE, i+1)
		v4 = Vector3(0, heightmap[0][i] / TILE_SIZE, i)
		var r = create_face(v1, v2, v3, v4)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		UVs.append_array(r[2])
		# border with X = tiles_w
		v1 = Vector3(tiles_w-1, heightmap[tiles_w-1][i] / TILE_SIZE, i)
		v2 = Vector3(tiles_w-1, heightmap[tiles_w-1][i+1] / TILE_SIZE, i+1)
		v3 = Vector3(tiles_w-1, 0, i+1)
		v4 = Vector3(tiles_w-1, 0, i)
		r = create_face(v1, v2, v3, v4)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		UVs.append_array(r[2])

	var array_mesh : ArrayMesh = ArrayMesh.new()
	var arrays : Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals 
	arrays[ArrayMesh.ARRAY_TEX_UV] = UVs 
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$Terrain.mesh = array_mesh
	print("Terrain vertices: %d" % vertices.size())

func create_water_mesh():
	var vertices : PoolVector3Array = PoolVector3Array()
	var normals : PoolVector3Array = PoolVector3Array()
	var v1 = Vector3(0, WATER_HEIGHT, 0)
	var v2 = Vector3(0, WATER_HEIGHT, size_h * 64)
	var v3 = Vector3(size_w * 64, WATER_HEIGHT, size_h * 64)
	var v4 = Vector3(size_w * 64, WATER_HEIGHT, 0)
	var r = create_face(v1, v2, v3, v4)
	vertices.append_array(r[0])
	normals.append_array(r[1])

	var array_mesh : ArrayMesh = ArrayMesh.new()
	var arrays : Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$WaterPlane.mesh = array_mesh

func set_view(zoom):
	var values = [[[29.919, -74.68, 26.682], [-0.929, -0.185, -0.320]],
				[[26.51, -66.452, 40.662], [-0.918, -0.183, -0.351]],
				[[22.649, -57.13, 53.812], [-0.905, -0.180, -0.386]],
				[[18.364, -46.784, 66.033], [-0.887, -0.176, -0.426]],
				[[18.364, -46.784, 66.033], [-0.887, -0.176, -0.426]]]
	var value = values[zoom-1]
	var trans = transform
	trans.basis.x =  -transform.basis.x
	trans.basis.y =  transform.basis.z
	trans.basis.z =  transform.basis.y
	trans = trans.translated(Vector3(value[0][0], value[0][1], value[0][2]))
	trans = trans.rotated(Vector3(1.00, 0.00, 0.00), value[1][0])
	trans = trans.rotated(Vector3(0.00, 1.00, 0.00), value[1][2])
	trans = trans.rotated(Vector3(0.00, 0.00, 1.00), value[1][1])
	#trans = trans.scaled(Vector3(0.1, 0.1, 0.1))
	var trans_corr = transform
	trans.origin = Vector3(-64.0, 200.0, -64.0)
	
	$KinematicBody/Camera.transform = trans
	trans.origin = Vector3(-96.0, 200.0, -64.0)
	$Sun.transform = trans
	$Terrain.material_override.set_shader_param("zoom", zoom)
	
func height_to_uv(height, flatness):
	var inst_key
	if flatness > 0.8:
		var temp = min(int((height) * 1.312), 31)
		var moist = 10
		inst_key = $Terrain.tm_table[temp][moist]
	else:
		inst_key = 68
	return self.uv_dict[inst_key]
