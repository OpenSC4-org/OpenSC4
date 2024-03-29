extends DBPFSubfile

class_name ExemplarSubfile

var parent_cohort = {}
var num_properties: int
var properties = {}
var ind
var keys_dict = {}

func _init(index):
	super(index)
	pass

func load(file, dbdf=null):
	super.load(file, dbdf)
	file.seek(index.location)
	ind = 0
	assert(len(raw_data) > 0, "DBPFSubfile.load: no data")
	# 4 bytes (char) - signature
	var signature = raw_data.subarray(ind, ind+3).get_string_from_ascii()
	assert(signature == "EQZB", "DBPFSubfile.load: not an Exemplar file")
	ind += 4
	# 4 bytes - parent cohort indicator always 0x23232331
	ind += 4
	self.parent_cohort["T"] = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
	ind += 4
	self.parent_cohort["G"] = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
	ind += 4
	self.parent_cohort["I"] = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
	ind += 4
	self.num_properties = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
	ind += 4
	for _property in range(self.num_properties):
		var key = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
		ind += 4
		# 1 Byte spacing always 0x00
		ind += 1
		var type = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
		ind += 4
		var multi :bool = (type & 0xF000) > 0
		var format :int = type & 0xF
		var value
		var length = 1
		if multi:
			length = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
			ind += 4
			if format == 0xC: #string
				value = raw_data.subarray(ind, ind+(length-1)).get_string_from_ascii()
				ind += length
			else:
				value = []
				for _i in range(length):
					value.append(self.val_from_format(format))
		else:
			value = self.val_from_format(format)
		self.properties[key] = value
	return OK

	
func get_int_from_bytes(bytearr):
	var r_int = 0
	var shift = 0
	for byte in bytearr:
		r_int = (r_int) | (byte << shift)
		shift += 8
	return r_int
	
func get_float_from_bytes(bytearr):
	var buff = StreamPeerBuffer.new()
	buff.data_array = bytearr
	return buff.get_float()
	
func val_from_format(format):
	"storing less thant 32bit ints as 32bit ints seems bad, should do this in C++ to remedy that"
	if format == 0x1: #Uint8
		var val = raw_data[ind]
		ind += 1
		return val
	elif format == 0x2: #Uint16 not used?
		var val = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
		ind += 2
		return val
	elif format == 0x3: #Uint32
		var val = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
		ind += 4
		return val
	elif format == 0x4:  #Uint64? not used?
		var val = self.get_int_from_bytes(raw_data.subarray(ind, ind+7))
		ind += 8
		return val
	elif format == 0x5: #int8? not used?
		var val = raw_data[ind]
		ind += 1
		return val
	elif format == 0x6: #int16? not used?
		var val = self.get_int_from_bytes(raw_data.subarray(ind, ind+1))
		ind += 2
		return val
	elif format == 0x7: #int32? not used?
		var val = self.get_int_from_bytes(raw_data.subarray(ind, ind+3))
		ind += 4
		return val
	elif format == 0x8: #int64? not used?
		var val = self.get_int_from_bytes(raw_data.subarray(ind, ind+7))
		ind += 8
		return val
	elif format == 0x9: #float32
		var val = self.get_float_from_bytes(raw_data.subarray(ind, ind+3))
		ind += 4
		return val
	elif format == 0xA: #float64?
		var val = self.get_float_from_bytes(raw_data.subarray(ind, ind+7))
		ind += 8
		return val
	elif format == 0xB: #bool
		var val = raw_data[ind]
		ind += 1
		return (val != 0)
	else:
		print("ERROR, unkown format: %d", format)
		
func key_description(key):
	if len(self.keys_dict) == 0:
		var file = File.new()
		file.open("res://exemplar_types.dict", File.READ)
		self.keys_dict = str_to_var(file.get_as_text())
		file.close()
	var ret = null
	if self.keys_dict.keys().has(key):
		ret = self.keys_dict[key]
	return ret
	


