extends Node
class_name INI

var sections = {}
var file_path

func _init(path):
	file_path = path
	var file = FileAccess.open(file_path, FileAccess.READ)
	var current_section = ""
	if file == null:
		var err = FileAccess.get_open_error()
		Logger.error("Couldn't load file %s. Error: %s " % [file_path, err])
		push_error(err)
		return
	while file.get_position() < file.get_length():
		var line = file.get_line()
		line = line.strip_edges(true, true)
		if line.length() == 0:
			continue
		if line[0] == '#' or line[0] == ';':
			continue
		if line[0] == '[':
			current_section = line.substr(1, line.length() - 2)
			sections[current_section] = {}
		else:
			var key = line.split('=')[0]
			var value = line.split('=')[1]
			sections[current_section][key] = value
	
	DebugUtils.print_dict(sections, self)
	

func save_file():
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	for section in sections.keys():
		file.store_line('[' + section + ']')
		for line in sections[section].keys():
			file.store_line(line + '=' + sections[section][line])
		
