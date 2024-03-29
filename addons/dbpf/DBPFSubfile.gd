extends RefCounted 
class_name DBPFSubfile

var index:SubfileIndex
var raw_data:PackedByteArray
var stream:StreamPeerBuffer

func _init(idx:SubfileIndex):
	self.index = idx

func load(file: FileAccess, dbdf: DBDFEntry = null):
	file.seek(index.location)
	if dbdf != null:
		raw_data = decompress(file, index.size - 9, dbdf)
	else:
		raw_data = file.get_buffer(index.size)
	stream = StreamPeerBuffer.new()
	stream.data_array = raw_data

func decompress(file: FileAccess, length: int, dbdf: DBDFEntry) -> PackedByteArray:
	var buf:PackedByteArray
	var answer:PackedByteArray = PackedByteArray()
	var numplain:int
	var numcopy:int
	var offset:int
	var byte1:int
	var byte2:int
	var byte3:int
	var fromoffset:int

	file.get_32() # 4 redundant bytes
	file.get_16() # Compression type
	var decompressed_size = file.get_8() * 256 * 256
	decompressed_size += file.get_8() * 256
	decompressed_size += file.get_8()
	if decompressed_size != dbdf.final_size:
		print("WARNING: decompressed size does not match expected size")
		print("Expected: %d" % dbdf.final_size)
	
	while (length > 0):
		var cc = file.get_8()
		length -= 1
		byte1 = 0
		byte2 = 0
		byte3 = 0
		if cc >= 252:
			numplain = cc & 0x03
			if numplain > length:
				numplain = length
			numcopy = 0
			offset = 0
		elif cc >= 224:
			numplain = (cc - 0xdf) << 2
			numcopy = 0
			offset = 0
		elif cc >= 192:
			length -= 3
			byte1 = file.get_8()
			byte2 = file.get_8()
			byte3 = file.get_8()
			numplain = cc & 0x03
			numcopy = ((cc & 0x0c) << 6) + 5 + byte3
			offset = ((cc & 0x10) << 12) + (byte1 << 8) + byte2
		elif cc >= 128:
			length -= 2
			byte1 = file.get_8()
			byte2 = file.get_8()
			numplain = (byte1 & 0xc0) >> 6
			numcopy = (cc & 0x3f) + 4
			offset = ((byte1 & 0x3f) << 8) + byte2
		else:
			length -= 1
			byte1 = file.get_8()
			numplain = (cc & 0x03)
			numcopy = ((cc & 0x1c) >> 2) + 3
			offset = ((cc & 0x60) << 3) + byte1
		
		length -= numplain
		if (numplain > 0):
			buf = file.get_buffer(numplain)
			answer.append_array(buf)
		
		fromoffset = len(answer) - (offset + 1)
		for i in range(numcopy):
			answer.append(answer[fromoffset+i])
		
	return answer
