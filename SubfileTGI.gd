extends Node

# TODO: id to class mapping loaded only once?

const TYPE_PNG = 0x856ddbac
const GROUP_UI_IMAGE = 0x46a006b0

static func get_file_type(type_id, group_id, instance_id):
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
		0xe86b1eef: "DBDF"
	}
	var group_dict = {
		0x00000001: "VIDEO,BW_CURSOR",
		0x46a006b0: "UI_IMAGE",
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
	}
	if type_dict.has(type_id):
		type = type_dict[type_id]
	if group_dict.has(group_id):
		group = group_dict[group_id]
	
	return "%s\t%s\t%08x" % [type, group, instance_id]
