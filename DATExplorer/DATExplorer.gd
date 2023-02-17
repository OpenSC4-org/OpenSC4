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

extends VBoxContainer

var dbpf_files_src = []
var tree : Tree
var file_treeitems : Dictionary
# Avoid loading all the files at once, instead group them by type IDs using these dictionaries of dictionaries
var typeid_count : Dictionary
var typeid_treeitems : Dictionary 
var filter_type_mask : int = 0xFFFFFFFF
var filter_type_id : int = 0
var filter_group_mask : int = 0xFFFFFFFF
var filter_group_id : int = 0
var filter_instance_mask : int = 0xFFFFFFFF
var filter_instance_id : int = 0


func _ready():
	tree = $DATTree
	base_load()
	$Filters.visible = true
	$DATTree.visible = true
	$SubfilePreview.visible = true
	$Filters/Type/Label.text = "Type filter"
	$Filters/Group/Label.text = "Group filter"
	$Filters/Instance/Label.text = "Instance filter"

func base_load():
	var root = tree.create_item()
	tree.set_hide_root(true)
	# Create all subtrees for each type ID
	# We assume dbpf_files is already filled with the files full paths
	# we use full paths to avoid clashing between two files with the same name in different directories
	for dbpf in Core.dbpf_files.values():
		Logger.info("Processing %s" % dbpf.path)
		typeid_count[dbpf.path] = {}
		typeid_treeitems[dbpf.path] = {}
		var file_treeitem = tree.create_item(root)
		file_treeitem.set_text(0, dbpf.path.get_file())
		file_treeitem.set_text(1, "%d subfiles" % dbpf.indices.size())
		file_treeitem.collapsed = true
		file_treeitems[dbpf.path] = file_treeitem
		for i in range(4):
			file_treeitem.set_selectable(i, false)
		for index in dbpf.indices.values():
			var type_id = index.type_id
			if typeid_count[dbpf.path].has(type_id):
				typeid_count[dbpf.path][type_id] += 1
			else:
				typeid_count[dbpf.path][type_id] = 1
				var type_id_tree_item = tree.create_item(file_treeitem)
				type_id_tree_item.set_text(0, Core.type_dict_to_text.get(type_id, "unknown type"))
				type_id_tree_item.set_text(1, "0x%08x" % type_id)
				type_id_tree_item.set_text(2, "%d" % dbpf.indices_by_type[type_id].size())
				typeid_treeitems[dbpf.path][type_id] = type_id_tree_item
				type_id_tree_item.collapsed = true
				for i in range(4):
					type_id_tree_item.set_selectable(i, false)
		# In each tree_item, write the amount of subfiles of that type
		for type_id in typeid_count[dbpf.path].keys():
			typeid_treeitems[dbpf.path][type_id].set_text(2, "%s subfiles" % typeid_count[dbpf.path][type_id])
	Logger.info("Done loading all files")

func check_filter(index : SubfileIndex) -> bool:
	return  (index.type_id & filter_type_mask) == filter_type_id & filter_type_mask\
			and\
			(index.group_id & filter_group_mask) == filter_group_id & filter_group_mask\
			and\
			(index.instance_id & filter_instance_mask) == filter_instance_id & filter_instance_mask

func add_subfile_to_tree(dbpf : DBPF, index : SubfileIndex) -> void:
	if typeid_treeitems[dbpf.path].has(index.type_id) == false:
		Logger.error("Type ID %d not found in file %s" % [index.type_id, dbpf.path])
		return
	var child = tree.create_item(typeid_treeitems[dbpf.path][index.type_id])
	child.set_text(0, SubfileTGI.get_file_type(index.type_id, index.group_id, index.instance_id))
	child.set_text(1, "0x%08x" % index.type_id)
	child.set_text(2, "0x%08x" % index.group_id)
	child.set_text(3, "0x%08x" % index.instance_id)

func _on_ApplyFilter_pressed():
	filter_type_id = ("0x%s" % $Filters/Type/ID.text).hex_to_int()
	filter_type_mask = ("0x%s" % $Filters/Type/Mask.text).hex_to_int()
	filter_group_id = ("0x%s" % $Filters/Group/ID.text).hex_to_int()
	filter_group_mask = ("0x%s" % $Filters/Group/Mask.text).hex_to_int()
	filter_instance_id = ("0x%s" % $Filters/Instance/ID.text).hex_to_int()
	filter_instance_mask = ("0x%s" % $Filters/Instance/Mask.text).hex_to_int()

	# Debug: log the filters to check conversion is correct
	Logger.info("Filter type ID:       0x%08x" % filter_type_id)
	Logger.info("Filter type mask:     0x%08x" % filter_type_mask)
	Logger.info("Filter group ID:      0x%08x" % filter_group_id)
	Logger.info("Filter group mask:    0x%08x" % filter_group_mask)
	Logger.info("Filter instance ID:   0x%08x" % filter_instance_id)
	Logger.info("Filter instance mask: 0x%08x" % filter_instance_mask)

	# Clear the files in the tree
	for dbpf in Core.dbpf_files.values():
		for type_id in dbpf.indices_by_type.keys():
			while true:
				var child = typeid_treeitems[dbpf.path][type_id].get_children()
				if child == null:
					break
				else:
					child.free()

	for dbpf in Core.dbpf_files.values():
		for index in dbpf.indices.values():
			if check_filter(index):
				add_subfile_to_tree(dbpf, index)

func _on_DATTree_item_selected():
	var item = tree.get_selected()
	var type_id = item.get_text(1).hex_to_int()
	var group_id = item.get_text(2).hex_to_int()
	var instance_id = item.get_text(3).hex_to_int()
	$SubfilePreview.display_subfile(type_id, group_id, instance_id)
