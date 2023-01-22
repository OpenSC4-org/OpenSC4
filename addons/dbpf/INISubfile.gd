extends DBPFSubfile
class_name INISubfile

var sections = {}
var file_path
var cfgFile : ConfigFile

func _init(index).(index):
	pass

func load(file, dbdf=null):
	.load(file, dbdf)
	file.seek(index.location)

#	var current_section = ""
#	if err != OK:
#		Logger.error("Couldn't load file %s. Error: %s " % file_path, err )
#		return err
#	while ! file.eof_reached():
#		var line = file.get_line()
#		line = line.strip_edges(true, true)
#		if line.length() == 0:
#			continue
#		if line[0] == '#' or line[0] == ';':
#			continue
#		if line[0] == '[':
#			current_section = line.substr(1, line.length() - 2)
#			sections[current_section] = {}
#		else:
#			var key = line.split('=')[0]
#			var value = line.split('=')[1]
#			sections[current_section][key] = value
	
	#DebugUtils.print_dict(sections, self)
	

func get_as_cfg():
	var sections = {}
	var err = cfgFile.load(raw_data.get_string_from_ascii())
	if err != OK:
		Logger.error("Couldnt load as INI!")
		return {}
	else:
		pass

func save_file(name):
	cfgFile.save(name)
