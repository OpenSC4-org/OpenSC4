extends Node
class_name INISubfile

var sections = {}
var file_path

func _init(path):
	file_path = path
	var file = File.new() 
	var err = file.open(file_path, File.READ)
	var current_section = ""
	if err != OK:
		Logger.error("Couldn't load file %s. Error: %s " % file_path, err )
		return err
	while ! file.eof_reached():
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
	var file = File.new()
	file.open(file_path, File.WRITE)
	for section in sections.keys():
		file.store_line('[' + section + ']')
		for line in sections[section].keys():
			file.store_line(line + '=' + sections[section][line])
		
