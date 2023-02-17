# OpenSC4 - Open source reimplementation of Sim City 4
# Copyright (C) 2023 The OpenSC4 contributors
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

extends Node 

var subfile_indices : Dictionary
# TODO: read region_settings from file
var region_settings : Dictionary = {
	"show_borders" : true,
	"show_names" : true,
	"view_mode" : "satellite",
}
var sub_by_type_and_group : Dictionary
var dbpf_files: Dictionary
var game_dir = null

var type_dict_to_text = {
	0x6534284a: "exemplar",
	0x2026960b: "LTEXT",
	0x5ad0e817: "S3D",
	0x05342861: "cohorts",
	0x29a5d1ec: "ATC",
	0x09ADCD75: "AVP",
	0x7ab50e44: "FSH",
	0xea5118b0: "EFFDIR",
	0x856ddbac: "PNG",
	0xca63e2a3: "LUA",
	0xe86b1eef: "DBDF",
	0x00000000: "text",
	0x0a5bCf4b: "RUL",
	0xaa5c3144: "Cursor",
	0xa2e3d533: "KeyCursor",
	0x296678f7: "SC4Path",
}

# This dictionary should actually be a dictionary of dictionaries (type -> group)
var group_dict_to_text = {
	0x00000001: "VIDEO,BW_CURSOR",
	0x46a006b0: "UI_IMAGE",
	0x1abe787d: "UI_IMAGE2",
	0x22dec92d: "UI_TOOLSIMAGE",
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
	0xcb6b7bd9: "LE_ARROW_IMAGE",
	0x891b0e1a: "TERRAIN_FOUNDATION",
	0x2bc2759a: "TRANSIT_NETWORK_SHADOW",
	0x0986135e: "BASE_OVERLAY",
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
	0x0a554af5: "LTEXT/Audio UI Panel texts",
	0x0a554ae8: "LTEXT/General UI texts",
	0x0a554ae0: "LTEXT/Item visible name and description texts",
	0x0a419226: "LTEXT/In game error texts",
	0x2a592fd1: "LTEXT/Item plop/draw notification texts",
	0x4a5e093c: "LTEXT/Terrain tool texts",
	0x4a5cb171: "LTEXT/Funny random city loading message texts",
	0x6a231eaa: "LTEXT/Interactivity Feature Texts (MySim, UDriveIt, etc.)",
	0x6a231ea4: "LTEXT/News ticker message texts",
	0x6a3ff01c: "LTEXT/Game UI Texts",
	0x6a4eb3f7: "LTEXT/Population Text",
	0x6a554afd: "LTEXT/Misc. Item Names/Descriptions (2)",
	0x8a635d24: "LTEXT/Audio filename to description texts",
	0x8a5e03ec: "LTEXT/Disaster texts",
	0x8a4924f3: "LTEXT/About SC4 window HTML text",
	0xca554b03: "LTEXT/Popup window HTML texts",
	0xea231e96: "LTEXT/Misc. Texts",
	0xea5524eb: "LTEXT/Misc. Item Names/Descriptions (1)",
	0xeafcb180: "LTEXT/Plugin Install Text",
}


# TODO Generate these dictionaries from the above
var type_dict = {
	"LTEXT": 0x2026960b,
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

func _type_int_2_str(dict, number:int) -> String:
	"""
	Tries to number into text based on dicionary
	Returns empty string if not found.
	"""
	var result : String
	var keys = dict.keys()
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
	if not subfile_indices.has(SubfileTGI.TGI2str(type_id, group_id, instance_id)):
		Logger.error("Unknown subfile %s" % SubfileTGI.get_file_type(type_id, group_id, instance_id))
		return null
	else:
		var index = subfile_indices[SubfileTGI.TGI2str(type_id, group_id, instance_id)]
		return index.dbpf.get_subfile(type_id, group_id, instance_id, subfile_class)

func add_dbpf(dbpf : DBPF):
	if not dbpf_files.has(dbpf.path):
		dbpf_files[dbpf.path] = dbpf
	for ind_key in dbpf.indices.keys():
		var index = dbpf.indices[ind_key]
		# Don't report DBDF "overwrite" with the type id
		if subfile_indices.has(ind_key) and index.type_id != 0xe86b1eef: # and not (index.type_id == "DBPF" and index.group_id == 0xe86b1eef and index.instance_id == 0x286b1f03):
			Logger.error("File '%s' overwrites subfile %s" % [dbpf.path, SubfileTGI.get_file_type(index.type_id, index.group_id, index.instance_id)])
		subfile_indices[ind_key] = dbpf.indices[ind_key]
		if not sub_by_type_and_group.keys().has([index.type_id, index.group_id]):
			sub_by_type_and_group[[index.type_id, index.group_id]] = {}
		sub_by_type_and_group[[index.type_id, index.group_id]][index.instance_id] = (dbpf.indices[ind_key])

func get_gamedata_path(path: String) -> String:
	return "%s/%s" % [Core.game_dir, path]
