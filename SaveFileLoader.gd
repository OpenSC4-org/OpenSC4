extends Node

var SC4ReadRegionalCity = load("res://SC4ReadRegionalCity.gd");
var SC4City__WriteRegionViewThumbnail = load("res://SC4City__WriteRegionViewThumbnail.gd")
var SC4Subfile = load("res://SC4Subfile.gd")
var SubfileIndex = load("res://SubfileIndex.gd")
var DBDF = load("res://DBDF.gd");
var region_view_thumbnails = []
var subfiles = {}

# Size, in pixels, of the tile base
var TILE_BASE_HEIGHT = 18
var TILE_BASE_WIDTH = 90

# Called when the node enters the scene tree for the first time.
func _ready():
	display()

func _init(filepath):
	# Open the file
	var file = File.new()
	var err = file.open(filepath, File.READ)
	if err != OK:
		return err
	# Read the file
	# Check that the first four bytes are DBPF
	var dbpf = file.get_buffer(4).get_string_from_ascii();
	if (dbpf != "DBPF"):
		return ERR_INVALID_DATA
	# Get the version
	var _version_major = file.get_32()
	var _version_minor = file.get_32()
	# useless bytes
	for _i in range(3):
		file.get_32()
	var _date_created = OS.get_datetime_from_unix_time(file.get_32())
	var _date_modified = OS.get_datetime_from_unix_time(file.get_32())
	var _index_major_version = file.get_32()
	var index_entry_count = file.get_32()
	var index_first_offset = file.get_32()
	var _hole_entry_count = file.get_32()
	var _hole_offset = file.get_32()
	var _hole_size = file.get_32()
	var _index_minor_version = file.get_32()
	var _index_offset = file.get_32()
	var _unknown = file.get_32()
	file.seek(index_first_offset)

	var _regional_views = {}

	var indices = []
	var compressed_files = {}

	for _i in range(index_entry_count):
		indices.append(SubfileIndex.new(file))

	for index in indices:
		if index.type_id == 0xe86b1eef:
			var dbdf = DBDF.new()
			dbdf.load(file, index.location, index.size)
			for compressed_file in dbdf.entries:
				compressed_files[[compressed_file.type_id, compressed_file.group_id, compressed_file.instance_id]] = compressed_file 

	for index in indices:
		var subfile
		var dbdf
		if [index.type_id, index.group_id, index.instance_id] in compressed_files:
			dbdf = compressed_files[[index.type_id, index.group_id, index.instance_id]]
		else:
			dbdf = null

		if index.type_id == 0xca027edb:
			subfile = SC4ReadRegionalCity.new(index)	
			subfile.load(file, dbdf)
		elif index.type_id == 0x8a2482b9:
			subfile = SC4City__WriteRegionViewThumbnail.new(index)
			if subfile.load(file, dbdf) != OK:
				print('Error')
				return
			region_view_thumbnails.append(subfile)
		else:
			continue
		subfiles[[index.type_id, index.group_id, index.instance_id]] = subfile


func display():
	# Get the regional city info
	var city_info = self.subfiles[[0xca027edb, 0xca027ee1, 0]]
	var city_sprite = self.region_view_thumbnails[0].sprite
	var grid = $"../BaseGrid"
	var pos_on_grid = grid.map_to_world(Vector2(city_info.location[0], city_info.location[1] ))
	# The height of a tile if it were completely flat
	var expected_height = 65 * city_info.size[1]
	# Adjust the tile placement
	pos_on_grid.y -= (city_sprite.texture.get_height() - expected_height)
	pos_on_grid.x -= 28 * (city_info.size[0]-1)
	$"../BaseGrid".add_child(city_sprite)
	city_sprite.translate(pos_on_grid)

func _on_press():
	print("Hello")

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
