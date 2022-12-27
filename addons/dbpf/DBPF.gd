extends Resource

# See details: https://wiki.sc4devotion.com/index.php?title=DBPF

class_name DBPF # Database Packed File

var subfiles : Dictionary
var compressed_files : Dictionary
var indices : Dictionary
var indices_by_type : Dictionary
var indices_by_type_and_group : Dictionary
var all_types : Dictionary
var file : File
var path : String

export (Dictionary) var ui_region_textures: Dictionary = {}

func _init(filepath : String):
	self.path = filepath
	# Open the file
	self.file = File.new()
	var err = file.open(filepath, File.READ)
	if err != OK:
		return err
	# Read the file
	# Check that the first four bytes are DBPF
	var dbpf = self.file.get_buffer(4).get_string_from_ascii();
	if (dbpf != "DBPF"):
		return ERR_INVALID_DATA
	# Get the version
	var _version_major = self.file.get_32()
	var _version_minor = self.file.get_32()
	# useless bytes
	for _i in range(3):
		file.get_32()
	var _date_created = OS.get_datetime_from_unix_time(self.file.get_32())
	var _date_modified = OS.get_datetime_from_unix_time(self.file.get_32())
	var _index_major_version = self.file.get_32()
	var index_entry_count = self.file.get_32()
	var index_first_offset = self.file.get_32()
	var _hole_entry_count = self.file.get_32()
	var _hole_offset = self.file.get_32()
	var _hole_size = self.file.get_32()
	var _index_minor_version = self.file.get_32()
	var _index_offset = self.file.get_32()
	var _unknown = self.file.get_32()

	self.file.seek(index_first_offset)
	for _i in range(index_entry_count):
		var index = SubfileIndex.new(self)
		indices[[index.type_id, index.group_id, index.instance_id]] = index
		if not index.type_id in indices_by_type:
			indices_by_type[index.type_id] = [index]
		else:
			indices_by_type[index.type_id].append(index)

		if not [index.type_id, index.group_id] in indices_by_type_and_group:
			indices_by_type_and_group[[index.type_id, index.group_id]] = [index]
		else:
			indices_by_type_and_group[[index.type_id, index.group_id]].append(index)

	for index in indices.values():
		if index.type_id == 0xe86b1eef:
			var dbdf = DBDF.new()
			dbdf.load(file, index.location, index.size)
			for compressed_file in dbdf.entries:
				compressed_files[[compressed_file.type_id, compressed_file.group_id, compressed_file.instance_id]] = compressed_file 

func dbg_subfile_types():
	for index in indices.values():
		var subfile_type = SubfileTGI.get_file_type(index.type_id, index.group_id, index.instance_id).split("\t")[0]
		if subfile_type == null:
			subfile_type = "%08x" % index.type_id
		if all_types.has(subfile_type):
			all_types[subfile_type] += 1
		else:
			all_types[subfile_type] = 1
	print("All types found:")
	for type in all_types:
		print("%s: %d" % [type, all_types[type]])

func dbg_show_all_subfiles():
	print("=== %s" % self.path)
	print("=== ALL SUBFILES ===")
	for index in indices.values():
		print("%s (%d B)" % [SubfileTGI.get_file_type(index.type_id, index.group_id, index.instance_id), index.size])
	print("====================")

func all_subfiles_by_group(group_id : int):
	print("=== ALL SUBFILES BY GROUP %08x ===" % group_id)
	for index in indices.values():
		if index.group_id == group_id:
			print("%s (%d B)" % [SubfileTGI.get_file_type(index.type_id, index.group_id, index.instance_id), index.size])
	print("====================")

func get_subfile(type_id : int, group_id : int, instance_id : int, subfile_class) -> DBPFSubfile: 
	assert(self.indices.has([type_id, group_id, instance_id]), "Subfile not found (%08x %08x %08x)" % [type_id, group_id, instance_id])

	if subfiles.has([type_id, group_id, instance_id]) and subfiles[[type_id, group_id, instance_id]] != null:
		return subfiles[[type_id, group_id, instance_id]]

	var index  : SubfileIndex = self.indices[[type_id, group_id, instance_id]]

	# If the file is in the DBDF, then it's compressed
	var dbdf : DBDFEntry = null
	if [index.type_id, index.group_id, index.instance_id] in self.compressed_files:
		dbdf = compressed_files[[index.type_id, index.group_id, index.instance_id]]

	var subfile : DBPFSubfile = subfile_class.new(index)
	subfiles[[index.type_id, index.group_id, index.instance_id]] = subfile
	subfile.load(self.file, dbdf)
	return subfile
