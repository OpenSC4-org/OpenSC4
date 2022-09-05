extends Node 

var subfile_indices : Dictionary
var sub_by_type_and_group : Dictionary

func subfile(type_id : int, group_id : int, instance_id : int, subfile_class) -> DBPFSubfile:
	if not subfile_indices.has([type_id, group_id, instance_id]):
		print("ERROR: unknown subfile %s" % SubfileTGI.get_file_type(type_id, group_id, instance_id))
		return null
	else:
		var index = subfile_indices[[type_id, group_id, instance_id]]
		return index.dbpf.get_subfile(type_id, group_id, instance_id, subfile_class)

func add_dbpf(dbpf : DBPF):
	for ind_key in dbpf.indices.keys():
		var index = dbpf.indices[ind_key]
		if subfile_indices.has(ind_key):# and not (index.type_id == "DBPF" and index.group_id == 0xe86b1eef and index.instance_id == 0x286b1f03):
			print("File '%s' overwrites subfile %s" % [dbpf.path, SubfileTGI.get_file_type(index.type_id, index.group_id, index.instance_id)])
		subfile_indices[ind_key] = dbpf.indices[ind_key]
		if not sub_by_type_and_group.keys().has([index.type_id, index.group_id]):
			sub_by_type_and_group[[index.type_id, index.group_id]] = {}
		sub_by_type_and_group[[index.type_id, index.group_id]][index.instance_id] = (dbpf.indices[ind_key])
