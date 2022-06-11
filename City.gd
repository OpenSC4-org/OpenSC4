extends Spatial

var size_w : int = 4
var size_h : int = 4
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var savefile
const TILE_SIZE : int = 16
const WATER_HEIGHT : int = 250 / TILE_SIZE

func _ready():
	rng.randomize()
	savefile = Boot.current_city
	create_terrain()
	create_water_mesh()
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

func load_city_terrain(savefile : DBPF):
	var heightmap : Array = []
	var city_info = savefile.get_subfile(0xca027edb, 0xca027ee1, 0, SC4ReadRegionalCity)
	var terrain_info = savefile.get_subfile(0xa9dd6ff4, 0xe98f9525, 00000001, cSTETerrain__SaveAltitudes)
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
	var vertices = PoolVector3Array()
	var normals = PoolVector3Array()
	vertices.append(v1)
	vertices.append(v3)
	vertices.append(v2)
	vertices.append(v1)
	vertices.append(v4)
	vertices.append(v3)
	# calculate the normals of each face
	var v : Vector3 = v2 - v1
	var u : Vector3 = v3 - v1
	var w : Vector3 = v4 - v1
	var normal1 : Vector3 = v.cross(u).normalized()
	var normal2 : Vector3 = u.cross(w).normalized()
	for _k in range(3):
		normals.append(normal1)
	for _k in range(3):
		normals.append(normal2)

	return [vertices, normals]

func create_terrain():
	var vertices : PoolVector3Array = PoolVector3Array()
	var normals : PoolVector3Array = PoolVector3Array()
	# Random heightmap (for now)
	var heightmap : Array
	if savefile != null:
		heightmap = load_city_terrain(savefile)
	else:
		heightmap = gen_random_terrain(size_w * 64 + 1, size_h * 64 + 1)
	var tiles_w = size_w * 64 + 1
	var tiles_h = size_h * 64 + 1

	# Top surface 
	for i in range(tiles_w - 1):
		for j in range(tiles_h - 1):
			var v1 = Vector3(i,   heightmap[i  ][j  ] / TILE_SIZE, j  )
			var v2 = Vector3(i,   heightmap[i  ][j+1] / TILE_SIZE, j+1)
			var v3 = Vector3(i+1, heightmap[i+1][j+1] / TILE_SIZE, j+1)
			var v4 = Vector3(i+1, heightmap[i+1][j  ] / TILE_SIZE, j  )
			var r = create_face(v1, v2, v3, v4)
			vertices.append_array(r[0])
			normals.append_array(r[1])

	# Generate the borders
	for i in range(tiles_w - 1):
		# border with Z = 0
		var v1 = Vector3(i, heightmap[i][0] / TILE_SIZE, 0)
		var v2 = Vector3(i, 0, 0)
		var v3 = Vector3(i+1, 0, 0)
		var v4 = Vector3(i+1, heightmap[i+1][0] / TILE_SIZE, 0)
		var r = create_face(v3, v2, v1, v4)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		# border with Z = tiles_h
		v1 = Vector3(i, heightmap[i][tiles_h-1] / TILE_SIZE, tiles_h-1)
		v2 = Vector3(i, 0, tiles_h-1)
		v3 = Vector3(i+1, 0, tiles_h-1)
		v4 = Vector3(i+1, heightmap[i+1][tiles_h-1] / TILE_SIZE, tiles_h-1)
		r = create_face(v1, v2, v3, v4)
		vertices.append_array(r[0])
		normals.append_array(r[1])

	for i in range(tiles_h - 1):
		# border with X = 0
		var v1 = Vector3(0, heightmap[i][tiles_h-1] / TILE_SIZE, i)
		var v2 = Vector3(0, 0, i)
		var v3 = Vector3(0, 0, i+1)
		var v4 = Vector3(0, heightmap[i][tiles_h-1] / TILE_SIZE, i+1)
		var r = create_face(v1, v2, v3, v4)
		vertices.append_array(r[0])
		normals.append_array(r[1])
		# border with X = tiles_w
		v1 = Vector3(tiles_w-1, heightmap[tiles_w-1][i] / TILE_SIZE, i)
		v2 = Vector3(tiles_w-1, 0, i)
		v3 = Vector3(tiles_w-1, 0, i+1)
		v4 = Vector3(tiles_w-1, heightmap[tiles_w-1][i+1] / TILE_SIZE, i+1)
		r = create_face(v1, v2, v3, v4)
		vertices.append_array(r[0])
		normals.append_array(r[1])

	var array_mesh : ArrayMesh = ArrayMesh.new()
	var arrays : Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals 
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
