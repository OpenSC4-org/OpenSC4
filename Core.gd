extends Node 

var subfile_indices : Dictionary
var sub_by_type_and_group : Dictionary
var game_dir = null

# User settigns values are read from config.ini(BootScreen.gd)
# if not read then tohose defaults are used
var config_path = "user://config.ini"
var show_city_names : bool = true
var show_city_boundaries : bool = false
var satellite_view : bool = true # true for SatelliteView, false for Transportation Map
var current_region_name : String = "Timbuktu"

var type_dict_to_text = {
	0x6534284a: "LTEXT",
	0x5ad0e817: "S3D",
	0x05342861: "Cohorts",
	0x29a5d1ec: "ATC",
	0x09ADCD75: "AVP",
	0x7ab50e44: "FSH",
	0xea5118b0: "EFFDIR",
	0x856ddbac: "PNG",
	0xca63e2a3: "LUA",
	0xe86b1eef: "DBDF",
	0x00000000: "TEXT",
	0xaa5c3144: "unknown_type1",
	0x0a5bcf4b: "BRIDGE_RULES"
}
var group_dict_to_text = {
	0x00000001: "VIDEO,BW_CURSOR",
	0x46a006b0: "UI_IMAGE",
	0x1ABE787D: "UI_IMAGE2",
	0x22DEC92D: "UI_TOOLSIMAGE",
	0x8a5971c5: "UDI_SOUNDS_DATA",
	0x2a2458f9: "PROPS_ANIM",
	0x49a593e7: "NONPROPS_ANIM",
	0xaa5bcf57: "BRIDGE_RULES",
	0x49dd6e08: "CONFIG",
	0x2a4d1937: "EFFECTS1",
	0x2a4d193d: "EFFECTS2",
	0xaa4d1920: "EFFECTS3",
	0xaa4d1930: "EFFECTS4",
	0xaa4d1933: "EFFECTS5",
	0xca4d1943: "EFFECTS6",
	0xca4d1948: "EFFECTS7",
	0xea4d192a: "EFFECTS8",
	0x4a54e387: "SUBWAY_VIEW",
	0x4a42c073: "TRAFFIC_MEDIUM",
	0x0a4d1926: "SCHOOL_BELL_FIRE_ENGINES",
	0x6a4d193a: "FIRE_OBLITERATE",
	0x9dbdbf74: "SOUND_HITLISTS",
	0x4a4d1946: "PLOP_BUTTON_CLICK_DECAY_WIRE_FIRE_TOOLS",
	0xca88cc85: "ABANDONED",
	0xCB6B7BD9: "LE_ARROW_IMAGE",
	0x891B0E1A: "TERRAIN_FOUNDATION",
	0x2BC2759A: "TRANSIT_NETWORK_SHADOW",
	0x0986135E: "BASE_OVERLAY",
	0xbadb57f1: "SIMGLIDE",
	0x69668828: "TEXTURED_NETWORK_PATH",
	0xa966883f: "3D_NETWORK_PATH",
	0x6a386d26: "MENU_ICONS",
	0x89ac5643: "EXEMPLAR_TRANSIT_PIECES",
	0x67bddf0c: "ZONABLE_RESIDENTIAL_BUILDING_PARENTS",
	0x690f693f: "DATA_VIEW_PARENTS",
	0x6a297266: "MY_SIM_PARENT",
	0x7a4a8458: "CLOUDS_PARENT",
	0x47bddf12: "DEVELOPER_COMMERCIAL",
	0x96a006b0: "UI_XML",
	0x08000600: "UI_800x600",
	0x00000032: "CUR"
}


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
	"TEXT": 0x00000000,
	"unknown_type1": 0xaa5c3144,
	"BRIDGE_RULES": 0x0a5bcf4b
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
	"UI_800x600": 0x08000600,
	"CUR" : 0x00000032
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
	"TEXT": DBPFSubfile,
	"unknown_type1": CURSubfile,
	"BRIDGE_RULES": RULSubfile,
}

func _ready():
	read_user_config()

func _type_int_2_str(dict, number:int) -> String:
	"""
	Tries to number into text based on dicionary
	Returns empty string if not found.
	"""
	var result : String
	if dict.has(number):
		result = dict[number]
	return result


func _type_str_2_int(dict, text: String) -> int:
	"""
	Tries to translate string into number based on dicionary
	Return 0 if not found
	"""
	var number = 0
	if dict.has(text):
		number = dict[text]
	else:
		Logger.error("Could not translate %s into number. Not found." % text)
	return number


func get_list_instances(type_id_str:String, group_id_str: String):
	"""
	Provides list of all instances based on given type_id and group_id.
	type_id and group_id are first translated from String to int.
	The instances are taken from subfile_indices.
	"""
	var type_id = self._type_str_2_int(self.type_dict, type_id_str)
	var group_id = self._type_str_2_int(self.group_dict, group_id_str)
	
	var instances_list = []
	for key in subfile_indices.keys():
		if key[0] == type_id and key[1] == group_id:
			instances_list.append(key[2])
	return instances_list

func get_list_groups(type_id_str:String):
	"""
	Based on type_id it return list of all groups assosiated with this type_id.
	The type_id is first translated to the number and then a search is performed.
	It provides two outputs first is a list of groups in numbers and second
	same list of groups but names are put there where they are known.
	"""
	var type_id = self._type_str_2_int(self.type_dict, type_id_str)
	var groups_list = []
	# Collect the groups list
	for key in subfile_indices.keys():
		if key[0] == type_id and not groups_list.has(key[1]):
			groups_list.append(key[1])
	# Try to put names there
	var names = []
	for item in groups_list:
		var name = _type_int_2_str(self.group_dict_to_text,item)
		if not name:
			names.append("0x%08x" % item)
		else:
			names.append(name)
	return {
		"groups_list" : groups_list,
		"groups_names" : names,
	}

func get_subfile(type_id_str: String, group_id_str: String, instance_id : int) -> DBPFSubfile:
	"""
	This user friendly function like subfile.
	Input arguments are String and they are translated to numbers first.
	Then subfile function is called.
	"""
	var type_id = self._type_str_2_int(self.type_dict, type_id_str)
	var group_id = self._type_str_2_int(self.group_dict, group_id_str)
	var class_type = self._type_str_2_int(self.class_dict, type_id_str)
	var subfile = subfile(type_id, group_id, instance_id, class_type)
	return subfile
		

func subfile(type_id : int, group_id : int, instance_id : int, subfile_class) -> DBPFSubfile:
	if not subfile_indices.has([type_id, group_id, instance_id]):
		Logger.error("Unknown subfile %s" % SubfileTGI.get_file_type(type_id, group_id, instance_id))
		return null
	else:
		var index = subfile_indices[[type_id, group_id, instance_id]]
		#Logger.error("DEBUG: Wrong instance: %d" % instance_id)
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




func read_user_config():
	"""
	Read user configuration from config file
	It's not optimal, maybe it should be moved to another script (like Player settings)
	The same file is also opened from BootScreen, which is also not good approach
	"""
	var config = ConfigFile.new()
	var error = config.load(config_path)
	if error != 0:
		Logger.error("Cannot open config. %d", error)
		return
	if config.has_section("PlayerSettings"):
		if config.has_section_key("PlayerSettings", "show_city_names"):
			self.show_city_names = config.get_value("PlayerSettings", "show_city_names")
		if config.has_section_key("PlayerSettings", "show_city_boundaries"):
			self.show_city_boundaries = config.get_value("PlayerSettings", "show_city_boundaries")
		if config.has_section_key("PlayerSettings", "satellite_view"):
			self.show_city_boundaries = config.get_value("PlayerSettings", "satellite_view")
		if config.has_section_key("PlayerSettings", "region_name"):
			self.current_region_name = config.get_value("PlayerSettings", "region_name")
			

func _exit_tree():
	save_user_configuration()
	
func save_user_configuration():
	"""
	Save the options user selected in top menu in Region view
	
	"""
	var config = ConfigFile.new()
	var error = config.load(config_path)
	if error != 0:
		Logger.error("Cannot open config. %d", error)
		return
	config.set_value("PlayerSettings", "show_city_names", self.show_city_names)
	config.set_value("PlayerSettings", "show_city_boundaries", self.show_city_boundaries)
	config.set_value("PlayerSettings", "satellite_view", self.satellite_view)
	config.set_value("PlayerSettings", "region_name", self.current_region_name)
	config.save(config_path)
