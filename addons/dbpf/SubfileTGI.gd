extends Node
class_name SubfileTGI

# TODO: id to class mapping loaded only once?

const TYPE_PNG = 0x856ddbac
const GROUP_UI_IMAGE = 0x46a006b0

static func TGI2str(type_id : int, group_id : int, instance_id : int) -> String:
	return "%08x%08x%08x" % [type_id, group_id, instance_id]

static func TG2int(type_id : int, group_id : int) -> int:
	return type_id << 32 | group_id

static func get_file_type(type_id : int, group_id : int, instance_id : int) -> String:
	var type = "0x%08x" % type_id
	var group = "0x%08x" % group_id
	var type_dict = {
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
		0x00000000: "TEXT"
	}
	var group_dict = {
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
	}
	if type_dict.has(type_id):
		type = type_dict[type_id]
	if group_dict.has(group_id):
		group = group_dict[group_id]
	
	return "%s    %s    0x%08x" % [type, group, instance_id]

# TODO: change this terrible name
static func get_type_from_type(type_id : int) -> String:
	var type = "0x%08x" % type_id
	var type_dict = {
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
		0x00000000: "TEXT"
	}
	if type_dict.has(type_id):
		type = type_dict[type_id]
	return type

static func visualize_standalone(file : DBPFSubfile) -> void:
	var file_type = get_type_from_type(file.index.type_id)
	if file_type == "TEXT":
		print(file.data)


