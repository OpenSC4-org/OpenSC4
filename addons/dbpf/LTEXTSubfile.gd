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

class_name LTEXTSubfile

var text : String

func _init(index):
	super(index)
	pass

func load(file, dbdf=null):
	super.load(file, dbdf)
	text = ""
	var n_characters = stream.get_u16() # (2-byte unicode characters)
	# Check that we have the correct amount of characters
	var expected_characters = (stream.get_available_bytes() - 2) / 2
	if expected_characters < n_characters:
		print("LTEXTSubfile: Too few characters (%d < %d)" % [expected_characters, n_characters])
	var control = stream.get_u16()
	if control != 0x0010:
		Logger.debug("Wrong control code: 0x%04x (expects 0x0010)" % control)
		pass

	for i in range(n_characters):
		if stream.get_available_bytes() < 2:
			print("LTEXTSubfile: Unexpected end of stream")
			break
		text += char(stream.get_u16())
