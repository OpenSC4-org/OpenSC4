extends Node

class_name S3D_Group

var vertices =  PackedVector3Array([])
var UVs = PackedVector2Array([])
var	mat_id: int

# shader mat index, should handle picking the texturearray and layer that hold the mat
var mat_index: int

# s3d settings
var alphatest: bool
var depthtest: bool
var backfacecull: bool
var framebuffblnd: bool
var texturing: bool
var alphafunc: int
var depthfunc: int
var srcblend: int
var destblend: int
var alphathreshold: int
var wrapmodeU: bool
var wrapmodeV: bool
var magfilter: int
var minfilter: int
var group_name: String

func _init():
	pass
