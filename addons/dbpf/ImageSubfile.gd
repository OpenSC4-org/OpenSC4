extends DBPFSubfile

class_name ImageSubfile

var img

func _init(index).(index):
	pass

func load(file, dbdf=null):
	.load(file, dbdf)
	file.seek(index.location)
	assert(len(raw_data) > 0, "DBPFSubfile.load: no data")
	assert(raw_data[0] == 0x89 and raw_data[1] == 0x50 and raw_data[2] == 0x4E and raw_data[3] == 0x47, "DBPFSubfile.load: invalid magic")
	self.img  = Image.new()
	var err = img.load_png_from_buffer(raw_data)
	if err != OK:
		return err
	return OK

func get_as_texture():
	assert(self.img != null)
	var ret = ImageTexture.new()
	ret.create_from_image(self.img, 0)
	return ret
