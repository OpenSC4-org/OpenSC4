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
	var type = Core.type_dict_to_text.get(type_id, "0x%08x" % type_id)
	var group = Core.group_dict_to_text.get(group_id, "0x%08x" % group_id)
	
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


