extends Node 

var subfile_indices : Dictionary

func subfile(type_id : int, group_id : int, instance_id : int, subfile_class) -> DBPFSubfile:
	if not subfile_indices.has([type_id, group_id, instance_id]):
		print("ERROR: unknown subfile %s" % SubfileTGI.get_file_type(type_id, group_id, instance_id))
		return null
	else:
		var index = subfile_indices[[type_id, group_id, instance_id]]
		return index.dbpf.get_subfile(type_id, group_id, instance_id, subfile_class)

func add_dbpf(dbpf : DBPF):
	for index in dbpf.indices.values():
		if subfile_indices.has([index.type_id, index.group_id, index.instance_id]):
			print("File '%s' overwrites subfile %s" % [dbpf.filename, SubfileTGI.get_file_type(index.type_id, index.group_id, index.instance_id)])
		subfile_indices[[index.type_id, index.group_id, index.instance_id]] = index
	print("Added %d subfiles from %s" % [len(dbpf.indices), dbpf.filename])
