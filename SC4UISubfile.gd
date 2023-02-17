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

class_name SC4UISubfile

var root : Control = Control.new()
var rectRegex : RegEx = RegEx.new()
var colorRegex : RegEx = RegEx.new()
var imgGIRegex : RegEx = RegEx.new()
var vec2Regex : RegEx = RegEx.new()
var elementsByID : Dictionary = {}
var lines : Array = []

func _init(index).(index):
	rectRegex.compile("\\((?<x>-?\\d+),(?<y>-?\\d+),(?<width>-?\\d+),(?<height>-?\\d+)\\)")
	colorRegex.compile("\\((?<r>\\d+),(?<g>\\d+),(?<b>\\d+)\\)")
	imgGIRegex.compile("\\{(?<group>[0-9a-fA-F]{8}),(?<instance>[0-9a-fA-F]{8})\\}")
	vec2Regex.compile("\\((?<x>-?\\d+),(?<y>-?\\d+)\\)")

func string2color(string : String) -> Color:
	var result = colorRegex.search(string)
	return Color8(int(result.get_string('r')), int(result.get_string('g')), int(result.get_string('b')))

func string2rect(string : String) -> Rect2:
	var result = rectRegex.search(string)
	return Rect2(int(result.get_string('x')), int(result.get_string('y')), int(result.get_string('width')), int(result.get_string('height')))

func string2intlist(string : String) -> Array:
	var parts = string.lstrip("(").rstrip(")").split(",")
	var result = Array()
	for part in parts:
		result.append(int(part))
	return result

func string2vec2(string : String) -> Vector2:
	var result = vec2Regex.search(string)
	return Vector2(int(result.get_string('x')), int(result.get_string('y')))

func create_last_element(parts : Array, custom_classes : Dictionary) -> Control:
	var attributes = {}
	for i in range(1, len(parts)):
		var attr = parts[i].split("=")
		if len(attr) == 2:
			attributes[attr[0]] = attr[1]
	return create_element(attributes, custom_classes)


func load(file, dbdf=null):
	.load(file, dbdf)
	lines = stream.get_string(stream.get_available_bytes()).split("\n")

func add_to_tree(parent : Node, custom_classes : Dictionary):
	parent.add_child(self.root)
	root.set_anchor(MARGIN_LEFT, 0)
	root.set_anchor(MARGIN_TOP, 0)
	root.set_anchor(MARGIN_RIGHT, 1)
	root.set_anchor(MARGIN_BOTTOM, 1)
	var current_element : Control = self.root
	var last_element : Control = null
	# We add children to current_element
	# last_element is the last element we've created 
	for l in lines:
		if l.begins_with("#"):
			continue
		else:
			var parts = l.strip_edges().rstrip(">").lstrip("<").split(" ")
			var tag_name = parts[0]
			if tag_name == 'LEGACY': # Create a new element
				last_element = create_last_element(parts, custom_classes)
				# If current_element is null, then this is the root
				if current_element != null:
					current_element.add_child(last_element)
			# hierarchy navigation
			elif tag_name == 'CHILDREN':
				current_element = last_element
			elif tag_name == '/CHILDREN':
				current_element = current_element.get_parent()
	root.name = 'SC4 UI root'

func create_element(attributes : Dictionary, custom_classes : Dictionary) -> Control:
	var type = attributes.get('iid', 'none')
	var interpreted_attributes = interpret_attributes(attributes)
	var element = null
	# Check if this is a standard class without any particular behaviour,
	# or a class that's linked to in-game code
	#print(interpreted_attributes)
	var class_id = attributes.get('clsid', 'none')
	if attributes.get('id', '') in custom_classes: # magic number for a custom class?
		var custom_class_id = attributes.get('id', 0)
		element = custom_classes[custom_class_id].new(interpreted_attributes)
	# else, standard class, instance with the GZcom implementation
	elif type == 'IGZWinGen':
		element = GZWinGen.new(interpreted_attributes)
	elif type == 'IGZWinText':
		element = GZWinText.new(interpreted_attributes)
	elif type == 'IGZWinBtn':
		element = GZWinBtn.new(interpreted_attributes)
	elif type == 'IGZWinBMP': 
		element = GZWinBMP.new(interpreted_attributes)
	elif type == 'IGZWinFlatRect':
		element = GZWinFlatRect.new(interpreted_attributes)
	elif type == 'IGZWinTextEdit':
		element = TextEdit.new()
	elif type == 'IGZWinCustom':
		element = Control.new()
	elif type == 'IGZWinGrid':
		element = GridContainer.new()
	elif type == 'IGZWinSlider':
		element = HSlider.new()
	elif type == 'IGZWinCombo':
		element = CheckBox.new()
	elif type == 'IGZWinListBox':
		element = ScrollContainer.new()
	elif type == 'IGZWinTreeView':
		element = Tree.new()
	elif type == 'IGZWinScrollbar2':
		element = HSlider.new()
	elif type == 'IGZWinFolders':
		element = FileDialog.new()
	elif type == 'IGZWinLineINput':
		element = LineEdit.new()
	elif type == 'IGZWinFileBrowser':
		element = FileDialog.new()
	else:
		print("Unknown element type %s" % type)
		element = GZWinGen.new(interpreted_attributes)
	if element.name == '':
		if 'id' in interpreted_attributes:
			element.name = "%s-%s-%s" % [interpreted_attributes['clsid'], interpreted_attributes['id'], type]
		else:
			element.name = type
	if 'id' in attributes and not attributes['id'] in custom_classes:
		print("Missing custom class for id ", attributes['id'])

	return element

func interpret_attributes(attributes : Dictionary):
	var interpreted_attributes : Dictionary = {}
	for attr in attributes:
		if attr in ['area', 'imagerect', 'vscrollimagerect', 'hscrollimagerect']:
			interpreted_attributes[attr] = string2rect(attributes[attr])
		# TODO: get all color-type attributes from the Wiki
		elif attr in ['color', 'fillcolor', 'forecolor', 'backcolor', 'bkgcolor',
					  'colorfont?', 'highlightcolor', 'outlinecolor', 'caretcolor',
					  'olinecolor', 'colgridclr', 'rowgridclr', 'coloroutlineb',
					  'coloroutliner', 'coloroutlinet', 'coloroutlinel', 'coloroutline',
					  'colorright', 'colorbottom', 'colorleft', 'colortop', 'backgroundcolor',
					  'highlightcolor', 'backgroundcolor', 'highlightcolorbackground', 'highlightcolorforeground',
					  'columngridcolor', 'linegridcolor']:
			interpreted_attributes[attr] = string2color(attributes[attr])
		elif attr == 'id':
			interpreted_attributes[attr] = attributes[attr]
		elif attr in ['gutters']:
			interpreted_attributes[attr] = string2intlist(attributes[attr])
		elif attr.find('winflag_') != -1 or attr in ['edgeimage', 'moveable', 'sizeable', 'defaultkeys',
			'defaultkeys', 'closevisible', 'gobackvisible', 'minmaxvisible']:
			interpreted_attributes[attr] = attributes[attr] == 'yes'
		elif attr == 'image':
			var imgGI = imgGIRegex.search(attributes[attr])
			var type_id = 0x856ddbac
			# Godot hex_to_int function expects a 0x prefix
			var group_id = ("0x%s" % imgGI.get_string('group')).hex_to_int()
			var instance_id = ("0x%s" % imgGI.get_string('instance')).hex_to_int()
			var image = Core.subfile(type_id, group_id, instance_id, ImageSubfile)
			interpreted_attributes[attr] = image
		else:
			if false:
				print("[%s] %s = '%s'" % [attributes['clsid'], attr, attributes[attr]])
			interpreted_attributes[attr] = attributes[attr]
	return interpreted_attributes

