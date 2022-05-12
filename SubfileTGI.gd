extends Node

# TODO: id to class mapping loaded only once?

const TYPE_PNG = 0x856ddbac
const GROUP_UI_IMAGE = 0x46a006b0

static func get_file_type(type_id):
	var dict = {
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
	if dict.has(type_id):
		return dict[type_id]
	return null
