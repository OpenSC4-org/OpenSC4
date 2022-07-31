extends DBPFSubfile

class_name FSHSubfile

var img
var width
var height
var size
var mipmaps
var file_size

func _init(index).(index):
	pass

func load(file, dbdf=null):
	.load(file, dbdf)
	file.seek(index.location)
	var ind = 0
	assert(len(raw_data) > 0, "DBPFSubfile.load: no data")
	# 4 bytes (char) - signature
	var signature = raw_data.subarray(ind, ind+3).get_string_from_ascii()
	assert(signature == "SHPI", "DBPFSubfile.load: not an FSH file")
	ind += 4
	# 4 bytes (unint32) - total file size
	self.file_size = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
	ind += 4
	# 4 bytes (uint32) - number of entries
	var num_entr : int =  self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
	ind += 4
	# 4 bytes (char) - directory ID 
	var dir_id = raw_data.subarray(ind, ind+3).get_string_from_ascii()
	ind += 4
	
	# Directory
	var dir_bytes = raw_data.subarray(ind, ind+7)
	var directory = []
		
	while len(directory) < num_entr:
		# 4 bytes (char) - entry tag  // e.g. "br02"
		var tag = dir_bytes.subarray(0, 3).get_string_from_ascii()
		ind += 4
		# 4 bytes (uint32) - entry offset 
		var offset : int =  self.get_int_from_bytes(dir_bytes.subarray(4, 7))
		ind += 4
		directory.append(FSH_Entry.new(tag, offset))
		dir_bytes = raw_data.subarray(ind, ind+7)
		assert (ind < file_size, "error")
	
	# optional binary attachment (padding)
	# Note: this attachment is added only for 16 bytes alignment
	# 8 bytes (char) - ID string  // "Buy ERTS":
	var id_str = dir_bytes.get_string_from_ascii()
	ind += 8
	var pad = (int(ind/16))*16
	if pad != ind:
		ind = pad+16
	var entries = {}
	var dir_ind = 0
	# 1 byte (uint8) - entry ID  // 0x69
	for entry in directory:
		
		if dir_ind != 0:
			var prev = directory[dir_ind-1]
			prev.size = entry.offset - prev.offset
		dir_ind += 1
		ind = entry.offset
		entry.size = self.file_size - entry.offset
		# data
		# -header 16 bytes;
		# 1 byte (uint8) - record ID / entry type / image type
		entry.entry_id = raw_data[ind]
		ind += 1
		# 3 bytes (uint24) - size of the block not used
		entry.block_size = self.get_int_from_bytes(raw_data.subarray(ind, ind+2))
		ind += 3
		# 2 bytes (uint16) - image width
		entry.width = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
		ind += 2
		# 2 bytes (uint16) - image height
		entry.height = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
		ind += 2
		# 2 bytes (uint16) - X axis coordinate (Center X)
		entry.x_coord = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
		ind += 2
		# 2 bytes (uint16) - Y axis coordinate (Center Y)
		entry.y_coord = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
		ind += 2
		# 2 bytes - X axis position (Left X pos.)[uint12] + internal flag [uint1] + unknown [uint3]
		entry.x_pos = self.get_int_from_bytes(raw_data.subarray(ind, ind+1)) >> 2
		ind += 2
		# 2 bytes - Y axis position (Top Y pos.)[uint12] + levels count (mipmaps) [uint4]
		entry.y_pos = self.get_int_from_bytes(raw_data.subarray(ind, ind+1)) >> 2
		entry.mipmaps = 3&self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
		ind += 2
	# x bytes - image data 
	# x bytes - optional padding  // up to 16 bytes, filled with nulls
	# x bytes - optional palette (header + data)
	# x bytes - optional binary attachments (header + data)
	
		
	for entry in directory:
		
		var start = entry.offset+16
		var att_id = entry.entry_id
		
		entry.img = Image.new()
		if att_id == 96: # compressed image, DXT1 4x4 packed, 1-bit alpha 
			entry.size = ((entry.width * entry.height) / 16)*8
			var img_data = raw_data.subarray(start, start + entry.size-1)
			entry.img.create_from_data(entry.width, entry.height, false, Image.FORMAT_DXT1, img_data)
		elif att_id == 97: # compressed image, DXT3 4x4 packed, 4-bit alpha 
			entry.size = ((entry.width * entry.height) / 16)*16
			var img_data = raw_data.subarray(start, start + entry.size-1)
			entry.img.create_from_data(entry.width, entry.height, false, Image.FORMAT_DXT3, img_data)
		"""elif att_id == 123 or att_id == 125 or att_id == 127: # image with palette (256 colors), 24 and 32 bmp
			entry.img.load_bmp_from_buffer(img_data)"""
		assert(entry.img != null, "img load failed")
		self.img = entry.img
		self.width = entry.width
		self.height = entry.height
	return OK

	
func get_int_from_bytes(bytearr):
	var r_int = 0
	var shift = 0
	for byte in bytearr:
		r_int = (r_int) | (byte << shift)
		shift += 8
	return r_int
	
func get_as_texture():
	assert(self.img != null)
	var ret = ImageTexture.new()
	ret.create_from_image(self.img)
	return ret
