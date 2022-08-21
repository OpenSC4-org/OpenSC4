extends MeshInstance

var tmpMesh = ArrayMesh.new();
var vertices = PoolVector3Array()
var UVs = PoolVector2Array()
var color = Color(0.9, 0.1, 0.1)
var mat = self.get_material_override()
var st = SurfaceTool.new()
var tm_table
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():


	#mat.albedo_color = color
	st.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	for v in vertices.size(): 
		#st.add_color(color)
		st.add_uv(UVs[v])
		st.add_vertex(vertices[v])

	st.commit(tmpMesh)
	self.set_mesh(tmpMesh)
	
func generate_wateredges(HeightMap):
	var TGI_Tprop = {"T": 0x6534284a, "G": 0x88cd66e9, "I":0x00000001}
	var Terr_properties = Core.subfile(TGI_Tprop["T"], TGI_Tprop["G"], TGI_Tprop["I"], DBPFSubfile)
	"TODO figure out how to read exemplar files"
	var waterheight = 250.0
	var beachrange = 2
	var max_beach_height = 4.0 # this seems to be ignored
	var max_depth_water_alpha = 30.0
	
	var depth_range = max_depth_water_alpha + max_beach_height
	var watermap = PoolByteArray([])
	var watercoords = []
	for w in range(len(HeightMap)):
		watercoords.append([])
		for h in range(len(HeightMap[0])):
			if HeightMap[w][h] < waterheight:
				var m_y = (HeightMap[w][h] - waterheight)
				if m_y >= -max_depth_water_alpha:
					var nearness = ((depth_range-(m_y+max_depth_water_alpha))/depth_range)*255.0
					watermap.append_array([nearness, 0.0, 0.0, 0.0])
				else:
					watermap.append_array([255.0, 0.0, 0.0, 0.0])
				# scan neighbours
				var min_w = max(w - 1, 0.0)
				var max_w = min(w + 2, len(HeightMap))
				var min_h = max(h - 1, 0.0)
				var max_h = min(h + 2, len(HeightMap[0]))
				var found = false
				for n_w in range(min_w, max_w):
					for n_h in range(min_h, max_h):
						if HeightMap[n_w][n_h] > waterheight:
							watercoords[w].append(h)
							found = true
							break
					if found:
						break
			else:
				watermap.append_array([0.0, 0.0, 0.0, 0.0])
	var max_dist = sqrt(pow(beachrange+3, 2)*2)
	for w in range(len(watercoords)):
		for h in watercoords[w]:
			var min_w = max(w - (beachrange+3), 0.0)
			var max_w = min(w + (beachrange+4), len(HeightMap))
			var min_h = max(h - (beachrange+3), 0.0)
			var max_h = min(h + (beachrange+4), len(HeightMap[0]))
			for neigh_w in range(min_w, max_w):
				for neigh_h in range(min_h, max_h):
					var dist_str = (((1.0 - sqrt(pow(neigh_w - w, 2) + pow(neigh_h - h, 2))/max_dist) * max_beach_height)/depth_range)*255.0
					if dist_str > watermap[(neigh_h + (neigh_w * len(HeightMap)))*4]:
						watermap[(neigh_h + (neigh_w * len(HeightMap)))*4] = dist_str
					"""var neigh_y = (HeightMap[neigh_w][neigh_h] - waterheight)
					
					this range needs to go from -30 to 4
					
					
					if neigh_y <= (max_beach_height) and neigh_y >= -max_depth_water_alpha:
						var nearness = ((depth_range-(neigh_y+max_depth_water_alpha))/depth_range)*255.0
						watermap[(neigh_h + (neigh_w * len(HeightMap)))*4] = nearness"""
		"""
		this nearness results in a blocky effect, 
		preferable is a circular neighbor search where 
			if its value is less than new_value it gets overwritten
			with new value being dependant on its radial distance from current coord
				water tiles should be height dependant up to 30m depth
		"""
	var TGI_waterT = {"T": 0x7ab50e44, "G": 0x891b0e1a, "I":0x09187300}
	var water_imgs = []
	for zoom in range(5):
		water_imgs.append(Core.subfile(TGI_waterT["T"], TGI_waterT["G"], TGI_waterT["I"]+zoom, FSHSubfile))
		
	
	var water_text = TextureArray.new()
	var w_w = water_imgs[4].width
	var w_h = water_imgs[4].height
	var format = water_imgs[4].img.get_format()
	water_text.create (w_h, w_w, 5, format, 2)
	for i in range(len(water_imgs)):
		water_text.set_layer_data(water_imgs[i].img, i)
	var watermap_inv =[]
	for w in range(len(HeightMap)):
		
		for h in range(len(HeightMap[0])):
			var i = h * len(HeightMap)
			var j = (i + w)*4
			watermap_inv.append(watermap[j])
			watermap_inv.append(watermap[j-1])
			watermap_inv.append(watermap[j-2])
			watermap_inv.append(watermap[j-3])
	
	var shoreimg = Image.new()
	shoreimg.create_from_data(len(HeightMap), len(HeightMap[0]), false, Image.FORMAT_RGBA8, watermap_inv)
	#shoreimg.flip_x()
	#shoreimg.flip_y()
	var shoretex = ImageTexture.new()
	shoretex.create_from_image(shoreimg, 0)
	mat = self.get_material_override()
	mat.set_shader_param("watermap", shoretex)
	mat.set_shader_param("watertexture", water_text)
	mat.set_shader_param("depth_range", depth_range)
	mat.set_shader_param("max_depth", max_depth_water_alpha)
	mat.set_shader_param("noise_texture", $NoiseTexture.texture)
	mat.set_shader_param("noise_normals", $NoiseNormals.texture)	
	self.set_material_override(mat)
	var matT = self.get_parent().get_node("Terrain").get_material_override()
	matT.set_shader_param("watermap", shoretex)
	matT.set_shader_param("max_beach_ht", max_beach_height)
	matT.set_shader_param("beach_ht_range", depth_range)
	self.get_parent().get_node("Terrain").set_material_override(matT)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
