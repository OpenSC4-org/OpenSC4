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

extends GZWin 
class_name GZWinBMP

var texture : Texture = null

func _init(attributes).(attributes):
	if not 'image' in attributes:
		print(attributes)
	else:
		if attributes['image'] == null:
			set_texture(load("res://missing_subfile.png"))
		else:
			set_texture(attributes['image'].get_as_texture())

func set_texture(texture : Texture):
	self.texture = texture
	update()

func _draw():
	if self.texture != null:
		draw_texture(texture, get_position())
