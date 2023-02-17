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

extends PanelContainer

var current_preview : DBPFSubfile = null

# We presume the file is loaded and available in the `Core` storage
func display_subfile(type_id : int, group_id : int, instance_id : int) -> void:
	clear_preview()
	var type = Core.type_dict_to_text[type_id]
	if type == 'text':
		# TODO: also display the source code
		if group_id == 0x96A006B0 or group_id == 0x08000600: # UI subfile
			Logger.info("Previewing a UI file")
			var file = Core.subfile(type_id, group_id, instance_id, SC4UISubfile)
			# If the file had already been loaded, then the root won't be null
			if file.root != null:
				file.root.visible = true
			file.add_to_tree($UI, {})
			$UI.visible = true
			current_preview = file
	elif type == 'exemplar': # exemplar
		pass
	elif type == 'LTEXT': # LTEXT
		var file = Core.subfile(type_id, group_id, instance_id, LTEXTSubfile)
		$Text.text = file.text
		$Text.visible = true
	elif type == 'PNG':
		var file = Core.subfile(type_id, group_id, instance_id, ImageSubfile)
		$Image.texture = file.get_as_texture()
		$Image.visible = true
	else:
		$NoPreview.visible = true
		$NoPreview.text = "No preview available for this file (%08x, %08x, %08x)" % [type_id, group_id, instance_id]
	
func clear_preview():
	$Text.visible = false
	$NoPreview.visible = false
	$UI.visible = false
	$Image.visible = false
	# Hide the last previewed UI file
	if current_preview != null and (current_preview.index.group_id == 0x96A006B0 or current_preview.index.group_id == 0x08000600):
		current_preview.root.visible = false 

