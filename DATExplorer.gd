extends VBoxContainer

var dbpf_files_src = []
var dbpf_files = []
var tree : Tree

var DIRECTORY = "res://.dev/ui/Game/"

func _init():
	DIRECTORY = "res://"
	# Find all .dat files in the .dev directory
	var dir = Directory.new()
	var err = dir.open(DIRECTORY)
	if err != OK:
		print('Error opening dev directory: %s' % err)
		return
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with('.dat'):
			self.dbpf_files_src.append(file)
	dir.list_dir_end()

	# Load all .dat files
	for file in self.dbpf_files_src:
		var dbpf = DBPF.new('%s%s' % [DIRECTORY, file])
		dbpf_files.append(dbpf)

func _ready():
	tree = $DATTree
	$TypeFilter/FilterByTypeID.connect("pressed", self, "filter_by_type_id")
	$InstanceFilter/FilterByInstanceID.connect("pressed", self, "filter_by_instance_id")
	reload_filtered_by_type_id(0x0)

func reload_no_filter():
	$DATTree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	for file in self.dbpf_files:
		var file_child = tree.create_item(root)
		file_child.set_text(0,file.path)
		if file.indices_by_type.has(0):
			for subfile in file.indices.values():
				var subfile_child = tree.create_item(file_child)
				subfile_child.set_text(0,SubfileTGI.get_file_type(subfile.type_id, subfile.group_id, subfile.instance_id))

func reload_filtered_by_type_id(type_id):
	$DATTree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	var count = 0
	for file in self.dbpf_files:
		var file_child = tree.create_item(root)
		file_child.set_text(0,file.path)
		if file.indices_by_type.has(0):
			for subfile in file.indices_by_type[type_id]:
				var subfile_child = tree.create_item(file_child)
				subfile_child.set_text(0,SubfileTGI.get_file_type(subfile.type_id, subfile.group_id, subfile.instance_id))
				count += 1
	print("Found %d files with typeID filter 0x%08x" % [count, type_id])

func reload_filtered_by_instance_id(instance_id):
	$DATTree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	var count = 0
	for file in self.dbpf_files:
		var file_child = tree.create_item(root)
		file_child.set_text(0,file.path)
		if file.indices_by_type.has(0):
			for subfile in file.indices.values():
				if subfile.instance_id != instance_id:
					continue
				var subfile_child = tree.create_item(file_child)
				subfile_child.set_text(0,SubfileTGI.get_file_type(subfile.type_id, subfile.group_id, subfile.instance_id))
				count += 1
	print("Found %d files with instanceID filter 0x%08x" % [count, instance_id])

func filter_by_type_id():
	var value = $TypeFilter/TypeIDFilter.text.hex_to_int()
	print("Filtering type ID = 0x%08x" % value)
	reload_filtered_by_type_id(value)

func filter_by_instance_id():
	var value = $InstanceFilter/InstanceIDFilter.text.hex_to_int()
	print("Filtering instance ID = 0x%08x" % value)
	reload_filtered_by_instance_id(value)
