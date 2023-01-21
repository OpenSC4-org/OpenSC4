extends Node 

var subfile_indices : Dictionary
var sub_by_type_and_group : Dictionary
var game_dir = null

func get_subfile(type_id: String, group_id: String, instance_id : int) -> DBPFSubfile:
	var type_dict = {
		"LTEXT": 0x6534284a,
		"S3D": 0x5ad0e817,
		"Cohorts" : 0x05342861,
		"ATC": 0x29a5d1ec,
		"AVP": 0x09ADCD75,
		"FSH": 0x7ab50e44,
		"EFFDIR": 0xea5118b0,
		"PNG": 0x856ddbac,
		"LUA": 0xca63e2a3,
		"DBDF": 0xe86b1eef,
		"TEXT": 0x00000000
	}
	var group_dict = {
		"VIDEO,BW_CURSOR": 0x00000001,
		"UI_IMAGE": 0x46a006b0,
		"UI_IMAGE2": 0x1ABE787D,
		"UI_TOOLSIMAGE": 0x22DEC92D,
		"UDI_SOUNDS_DATA": 0x8a5971c5,
		"PROPS_ANIM": 0x2a2458f9,
		"NONPROPS_ANIM": 0x49a593e7,
		"BRIDGE_RULES": 0xaa5bcf57,
		"CONFIG": 0x49dd6e08,
		"EFFECTS1": 0x2a4d1937,
		"EFFECTS2": 0x2a4d193d,
		"EFFECTS3": 0xaa4d1920,
		"EFFECTS4": 0xaa4d1930,
		"EFFECTS5": 0xaa4d1933,
		"EFFECTS6": 0xca4d1943,
		"EFFECTS7": 0xca4d1948,
		"EFFECTS8": 0xea4d192a,
		"SUBWAY_VIEW": 0x4a54e387,
		"TRAFFIC_MEDIUM": 0x4a42c073,
		"SCHOOL_BELL_FIRE_ENGINES": 0x0a4d1926,
		"FIRE_OBLITERATE": 0x6a4d193a,
		"SOUND_HITLISTS": 0x9dbdbf74,
		"PLOP_BUTTON_CLICK_DECAY_WIRE_FIRE_TOOLS": 0x4a4d1946,
		"ABANDONED": 0xca88cc85,
		"LE_ARROW_IMAGE": 0xCB6B7BD9,
		"TERRAIN_FOUNDATION": 0x891B0E1A,
		"TRANSIT_NETWORK_SHADOW": 0x2BC2759A,
		"BASE_OVERLAY": 0x0986135E,
		"SIMGLIDE": 0xbadb57f1,
		"TEXTURED_NETWORK_PATH": 0x69668828,
		"3D_NETWORK_PATH": 0xa966883f,
		"MENU_ICONS": 0x6a386d26,
		"EXEMPLAR_TRANSIT_PIECES": 0x89ac5643,
		"ZONABLE_RESIDENTIAL_BUILDING_PARENTS": 0x67bddf0c,
		"DATA_VIEW_PARENTS": 0x690f693f,
		"MY_SIM_PARENT": 0x6a297266,
		"CLOUDS_PARENT": 0x7a4a8458,
		"DEVELOPER_COMMERCIAL": 0x47bddf12,
		"UI_XML": 0x96a006b0,
		"UI_800x600": 0x08000600
	}
	var class_dict = {
		"LTEXT": null,
		"S3D": null,
		"Cohorts" : null,
		"ATC": null,
		"AVP": null,
		"FSH": FSHSubfile,
		"EFFDIR": null,
		"PNG": ImageSubfile,
		"LUA": null,
		"DBDF": DBPFSubfile,
		"TEXT": null
	}	
	var type_id_int = type_dict[type_id]
	var group_id_int = group_dict[group_id]
	var class_type = class_dict[type_id]
	var subfile = subfile(type_id_int, group_id_int, instance_id, class_type)
	return subfile
		

func subfile(type_id : int, group_id : int, instance_id : int, subfile_class) -> DBPFSubfile:
	if not subfile_indices.has([type_id, group_id, instance_id]):
		Logger.error("Unknown subfile %s" % SubfileTGI.get_file_type(type_id, group_id, instance_id))
		return null
	else:
		var index = subfile_indices[[type_id, group_id, instance_id]]
		return index.dbpf.get_subfile(type_id, group_id, instance_id, subfile_class)

func add_dbpf(dbpf : DBPF):
	for ind_key in dbpf.indices.keys():
		var index = dbpf.indices[ind_key]
		if subfile_indices.has(ind_key):# and not (index.type_id == "DBPF" and index.group_id == 0xe86b1eef and index.instance_id == 0x286b1f03):
			Logger.error("File '%s' overwrites subfile %s" % [dbpf.path, SubfileTGI.get_file_type(index.type_id, index.group_id, index.instance_id)])
		subfile_indices[ind_key] = dbpf.indices[ind_key]
		if not sub_by_type_and_group.keys().has([index.type_id, index.group_id]):
			sub_by_type_and_group[[index.type_id, index.group_id]] = {}
		sub_by_type_and_group[[index.type_id, index.group_id]][index.instance_id] = (dbpf.indices[ind_key])
