extends "res://SC4Subfile.gd" 

var RegionViewCityThumbnail = load("res://RegionViewCityThumbnail.gd")

var sprite:RegionViewCityThumbnail

func _init(index).(index):
	pass

func load(file, dbdf=null):
	.load(file, dbdf)
	file.seek(index.location)
	assert(len(raw_data) > 0, "SC4Subfile.load: no data")
	assert(raw_data[0] == 0x89 and raw_data[1] == 0x50 and raw_data[2] == 0x4E and raw_data[3] == 0x47, "SC4Subfile.load: invalid magic")
	var img  = Image.new()
	var err = img.load_png_from_buffer(raw_data)
	if err != OK:
		return err
	sprite = RegionViewCityThumbnail.new()
	sprite.texture = ImageTexture.new()
	sprite.texture.create_from_image(img)
	return OK
