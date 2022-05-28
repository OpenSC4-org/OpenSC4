tool
extends ResourceFormatLoader
class_name DBPFLoader

func get_recognized_extensions():
	return ["DAT", "dat"]

func get_resource_type(path : String):
	var file = File.new()
	# Open the file and check for the DBPF magic
	file.open(path, File.READ)
	if file.read(4) != "DBPF":
		return ""
	return "Resource"

func handles_type(typename : String) -> bool:
	return typename == "DBPF"

func load(path : String, original_path : String) -> DBPF:
	var file = DBPF.new(path)

	# Find all PNG images
	var ui_indices = file.indices_by_type_and_group.get([SubfileTGI.TYPE_PNG, 0x1ABE787D], {})
	for index in ui_indices:
		var sprite = file.get_subfile(index.type_id, index.group_id, index.instance_id)
		print("Sprite %08x" % index.instance_id)
		if (index.instance_id & 0xffffff00) == 0x14416300:
			print("MATCHES")
			file.ui_region_textures[index.instance_id & 0x000000ff] = sprite.texture

	return file
