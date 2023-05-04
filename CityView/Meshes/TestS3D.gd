extends MeshInstance3D

var tmpMesh = ArrayMesh.new();
var vertices = PackedVector3Array()
var UVs = PackedVector2Array()
var color = Color(0.9, 0.1, 0.1)
var mat = self.get_material_override()
var st = SurfaceTool.new()
var tm_table

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
