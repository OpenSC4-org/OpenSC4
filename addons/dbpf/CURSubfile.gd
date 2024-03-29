extends DBPFSubfile

class_name CURSubfile

var n_images
var entries = []

func _init(index):
	super(index)
	pass

func load(file, dbdf=null):
	super.load(file, dbdf)
	file.seek(index.location)
	var ind = 0
	assert(len(raw_data) > 0, "DBPFSubfile.load: no data")
	# 4 bytes (char) - signature
	var signature = self.get_int_from_bytes(raw_data.subarray(ind+2, ind+3))
	assert(signature == 2, "DBPFSubfile.load: not a CUR file")
	ind += 4
	# 4 bytes (unint32) - total file size
	self.n_images = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
	ind += 2
	for n in range(n_images):
		var entry = CUR_Entry.new()
		entry.width = raw_data[ind]
		ind += 1
		entry.height = raw_data[ind]
		ind +=3
		entry.x_hotspot = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
		ind += 2
		entry.y_hotspot = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
		entry.vec_hotspot = Vector2(entry.x_hotspot, entry.y_hotspot)
		ind += 2
		entry.size = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
		ind += 4
		entry.offset = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
		ind += 4
		entries.append(entry)
	for entry in entries:
		ind = entry.offset
		if (raw_data[ind] == 0x89 and 
		raw_data[ind+1] == 0x50 and 
		raw_data[ind+2] == 0x4E and 
		raw_data[ind+3] == 0x47):
			entry.img  = Image.new()
			var img_data = raw_data.subarray(ind, ind+entry.size)
			entry.img.load_png_from_buffer(img_data)
		elif self.get_int_from_bytes(raw_data.subarray(ind, ind+3)) == 40:
			ind += 4
			var bmp_width = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
			ind += 4
			var bmp_height = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
			ind += 6
			var bpp = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
			ind += 2
			#var comp_meth = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
			ind += 4
			var img_size = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
			ind += 12
			#var n_colors = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
			ind += 8
			var bmp_size = (bpp/8) * bmp_width * bmp_height
			var bmp_header = [0x42, 0x4d, 
			(int(bmp_size)+54), (int(bmp_size)+54)>>8, (int(bmp_size)+54)>>16, (int(bmp_size)+54)>>24, 
			0x00, 0x00, 0x00, 0x00, 
			0x36, 0x00, 0x00, 0x00]
			var bmp_data = PackedByteArray(bmp_header)
			bmp_data.append_array(raw_data.subarray(ind-40, ind-1))
			bmp_data.append_array(raw_data.subarray(ind, ind+bmp_size-1))
			#bmp_data[22] = bmp_data[18]
			var temp_img = Image.new()
			temp_img.load_bmp_from_buffer(bmp_data)
			temp_img.decompress()
			temp_img = temp_img.get_rect(Rect2(Vector2(0.0, 0.0), Vector2(bmp_width, bmp_width)))
			var mask_data = raw_data.subarray(ind+bmp_size, raw_data.size()-1)
			for i in range(bmp_width):
				for j in range(0, bmp_width, 8):
					var k = (j / 8) + (i * 4)
					var l = ((bmp_width - (i+1)) * bmp_width + j) * 4
					temp_img.data["data"][l+3+28] = 255-min((mask_data[(k)] & 1) * 256, 255)
					temp_img.data["data"][l+3+24] = 255-min((mask_data[(k)] & 2) * 128, 255)
					temp_img.data["data"][l+3+20] = 255-min((mask_data[(k)] & 4) * 64, 255)
					temp_img.data["data"][l+3+16] = 255-min((mask_data[(k)] & 8) * 32, 255)
					temp_img.data["data"][l+3+12] = 255-min((mask_data[(k)] & 16) * 16, 255)
					temp_img.data["data"][l+3+8] = 255-min((mask_data[(k)] & 32) * 8, 255)
					temp_img.data["data"][l+3+4] = 255-min((mask_data[(k)] & 64) * 4, 255)
					temp_img.data["data"][l+3] = 255-min((mask_data[(k)] & 128) * 2, 255)
			entry.img = temp_img
	return OK

	
func get_int_from_bytes(bytearr):
	var r_int = 0
	var shift = 0
	for byte in bytearr:
		r_int = (r_int) | (byte << shift)
		shift += 8
	return r_int
	
func get_as_texture(entry_no = 0):
	assert(entries[entry_no].img != null)
	var ret = ImageTexture.new()
	ret.create_from_image(entries[entry_no].img) #,0
	return ret
