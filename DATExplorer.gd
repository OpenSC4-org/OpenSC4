extends VBoxContainer

var dbpf_files_src = []
var dbpf_files = []
var tree : Tree
var current_preview : DBPFSubfile = null

var DIRECTORY = "res://.dev/ui/Game/"

func load_dats():
	DIRECTORY = "/home/adrien/.steam/debian-installation/steamapps/common/SimCity 4 Deluxe"

	var dir = Directory.new()
	var err = dir.open(DIRECTORY)
	Logger.info("Opening directory %s" % DIRECTORY)
	if err != OK:
		Logger.error('Error opening dev directory: %s' % err)
		return
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with('.dat'):
			self.dbpf_files_src.append(file)
			Logger.info("Found file: %s" % file)
	dir.list_dir_end()

	# Load all .dat files
	for file in self.dbpf_files_src:
		var dbpf = DBPF.new('%s/%s' % [DIRECTORY, file])
		Logger.info("DBPF file %s loaded" % dbpf.path)
		dbpf_files.append(dbpf)
		Core.add_dbpf(dbpf)
	reload_no_filter()

func _ready():
	tree = $DATTree
	$TypeFilter/FilterByTypeID.connect("pressed", self, "filter_by_type_id")
	$InstanceFilter/FilterByInstanceID.connect("pressed", self, "filter_by_instance_id")
	$DirectoryChoice.popup()
	reload_filtered_by_type_id(0x0)

func reload_no_filter():
	$DATTree.clear()
	var root = tree.create_item()
	tree.set_hide_root(true)
	var count = 0
	for file in self.dbpf_files:
		var file_child = tree.create_item(root)
		file_child.set_text(0,file.path)
		if file.indices_by_type.has(0):
			for subfile in file.indices.values():
				add_subfile_to_tree(subfile)
				count += 1
	Logger.info("Found %d files" % [count])

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
				add_subfile_to_tree(subfile)
				count += 1
	Logger.info("Found %d files with typeID filter 0x%08x" % [count, type_id])

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
				add_subfile_to_tree(subfile)
				count += 1
	Logger.info("Found %d files with instanceID filter 0x%08x" % [count, instance_id])

func add_subfile_to_tree(index : SubfileIndex) -> void:
	var child = tree.create_item()
	child.set_text(0, SubfileTGI.get_file_type(index.type_id, index.group_id, index.instance_id))
	child.set_text(1, "0x%08x" % index.type_id)
	child.set_text(2, "0x%08x" % index.group_id)
	child.set_text(3, "0x%08x" % index.instance_id)

func filter_by_type_id():
	var value = $TypeFilter/TypeIDFilter.text.hex_to_int()
	Logger.info("Filtering type ID = 0x%08x" % value)
	reload_filtered_by_type_id(value)

func filter_by_instance_id():
	var value = $InstanceFilter/InstanceIDFilter.text.hex_to_int()
	Logger.info("Filtering instance ID = 0x%08x" % value)
	reload_filtered_by_instance_id(value)

func _on_DirectoryChoice_dir_selected(dir: String):
	DIRECTORY = dir 
	$Loading.visible = true 
	load_dats()
	$TypeFilter.visible = true
	$InstanceFilter.visible = true
	$DATTree.visible = true
	$FilePreview.visible = true
	$Loading.visible = false

func _on_DATTree_item_selected():
	$FilePreview/Loading.visible = false
	$FilePreview/TextView.visible = false
	var item = tree.get_selected()
	var type_id = item.get_text(1).hex_to_int()
	var group_id = item.get_text(2).hex_to_int()
	var instance_id = item.get_text(3).hex_to_int()
	if group_id == 0x96A006B0 or group_id == 0x08000600: # UI subfile
		# Hide the last previewed UI file
		if current_preview != null and (current_preview.index.group_id == 0x96A006B0 or current_preview.index.group_id == 0x08000600):
			current_preview.root.visible = false 
		Logger.info("Previewing a UI file")
		var file = Core.subfile(type_id, group_id, instance_id, SC4UISubfile)
		# If the file had already been loaded, then the root won't be null
		if file.root != null:
			file.root.visible = true
		$FilePreview/Loading.visible = false
		file.add_to_tree($FilePreview/UI, {})
		current_preview = file
	else:
		Logger.info("No preview available for this file (%08x, %08x, %08x)" % [type_id, group_id, instance_id])

