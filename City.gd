extends Spatial

var size_w : int = 1
var size_h : int = 1
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var savefile

func _ready():
	rng.randomize()
	savefile = Boot.current_city
	create_terrain()
	create_water_plane()
	pass

func gen_random_terrain(width : int, height : int) -> Array:
	var heightmap : Array = []
	var noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = 2
	noise.period = 20
	noise.persistence = 0.8
	for i in range(width):
		heightmap.append([])
		for j in range(height):
			var h = noise.get_noise_2d(i, j) * 15
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

func create_terrain():
	var vertices : PoolVector3Array = PoolVector3Array()
	var normals : PoolVector3Array = PoolVector3Array()
	# Random heightmap (for now)
	var heightmap = load_city_terrain(savefile)
	var tiles_w = size_w * 64 + 1
	var tiles_h = size_h * 64 + 1

	# Generate triangles from the heightmap
	for i in range(tiles_w - 1):
		for j in range(tiles_h - 1):
			#(0, 0)       (1, 0)
			#	    1 - 4
			#	    | \ |
			#       2 - 3
			#(0, 1)       (1, 1)
			var v1 = Vector3(i,   heightmap[i  ][j  ], j  )
			var v2 = Vector3(i,   heightmap[i  ][j+1], j+1)
			var v3 = Vector3(i+1, heightmap[i+1][j+1], j+1)
			var v4 = Vector3(i+1, heightmap[i+1][j  ], j  )
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

	var array_mesh : ArrayMesh = ArrayMesh.new()
	var arrays : Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals 
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$Terrain.mesh = array_mesh

func create_water_plane():
	var vertices : PoolVector3Array = PoolVector3Array()
	var normals : PoolVector3Array = PoolVector3Array()
	var v1 = Vector3(0, 0, 0)
	var v2 = Vector3(0, 0, size_h * 64)
	var v3 = Vector3(size_w * 64, 0, size_h * 64)
	var v4 = Vector3(size_w * 64, 0, 0)
	vertices.append(v1)
	vertices.append(v3)
	vertices.append(v2)
	vertices.append(v1)
	vertices.append(v4)
	vertices.append(v3)
	for _k in range(6):
		normals.append(Vector3(0, 1, 0))

	var array_mesh : ArrayMesh = ArrayMesh.new()
	var arrays : Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	$WaterPlane.mesh = array_mesh
