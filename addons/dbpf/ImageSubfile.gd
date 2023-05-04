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

extends DBPFSubfile

class_name ImageSubfile

var img

func _init(index):
	pass

func load(file, dbdf=null):
	super.load(file, dbdf)
	file.seek(index.location)
	assert(len(raw_data) > 0) #,"DBPFSubfile.load: no data")
	assert(raw_data[0] == 0x89 and raw_data[1] == 0x50 and raw_data[2] == 0x4E and raw_data[3] == 0x47) #,"DBPFSubfile.load: invalid magic")
	self.img  = Image.new()
	var err = img.load_png_from_buffer(raw_data)
	if err != OK:
		return err
	return OK

func get_as_texture():
	assert(self.img != null)
	var ret = ImageTexture.new()
	ret.create_from_image(self.img) #,0
	return ret
