extends DBPFSubfile

class_name SC4UISubfile

var root : Control = null
var rectRegex : RegEx = RegEx.new()
var colorRegex : RegEx = RegEx.new()
var elementsByID : Dictionary = {}

func _init(index).(index):
	rectRegex.compile("\\((?<x>-?\\d+),(?<y>-?\\d+),(?<width>-?\\d+),(?<height>-?\\d+)\\)")
	colorRegex.compile("\\((?<r>\\d+),(?<g>\\d+),(?<b>\\d+)\\)")

func load(file, dbdf=null):
	.load(file, dbdf)
	var lines = stream.get_string(stream.get_available_bytes()).split("\n")
	var current_element : Control = null
	var last_element : Control = null
	for l in lines:
		if l.begins_with("#"):
			continue
		else:
			var parts = l.strip_edges().rstrip(">").lstrip("<").split(" ")
			var tag_name = parts[0]
			print(tag_name)
			if tag_name == 'LEGACY':
				var attributes = {}
				for i in range(1, len(tag_name)):
					var attr = parts[i].split("=")
					attributes[attr[0]] = attr[1]
				last_element = create_element(attributes)
				if current_element != null:
					current_element.add_child(last_element)
				else:
					current_element = last_element
				if root == null:
					root = current_element
			elif tag_name == 'CHILDREN':
				current_element = last_element
			elif tag_name == '/CHILDREN':
				current_element = current_element.get_parent()
	print("DEBUG")

func create_element(attributes : Dictionary) -> Control:
	var type = attributes['clsid']
	var element : Control = null
	if type == 'GZWinGen':
		element = Control.new()
	elif type == 'GZWinText':
		element = Label.new()
	elif type == 'GZWinTextEdit':
		element = TextEdit.new()
	elif type == 'GZWinBtn':
		element = Button.new()
	elif type == 'GZBmp':
		element = TextureRect.new()
	elif type == 'GZCustom':
		element = Control.new()
	elif type == 'GZWinGrid':
		element = GridContainer.new()
	elif type == 'GZWinFlatRect':
		element = ColorRect.new()
	elif type == 'GZWinSlider':
		element = HSlider.new()
	elif type == 'GZWinCombo':
		element = CheckBox.new()
	elif type == 'GZWinListBox':
		element = ScrollContainer.new()
	elif type == 'GZWinTreeView':
		element = Tree.new()
	elif type == 'GZWinScrollbar2':
		element = HSlider.new()
	elif type == 'GZWinFolders':
		print("GZWinFolders")
		element = FileDialog.new()
	elif type == 'GZWinLineINput':
		element = LineEdit.new()
	elif type == 'GZWinFileBrowser':
		element = FileDialog.new()
	else:
		print("Unknown element type %s" % type)
		element = Control.new()

	interpret_attributes(element, attributes)
	return element

func interpret_attributes(element : Control, attributes : Dictionary):
	for attr in attributes:
		if attr == 'area':
			var result = rectRegex.search(attributes[attr])
			element.set_position(Vector2(int(result.get_string('x')), int(result.get_string('y'))))
			element.set_size(Vector2(int(result.get_string('width')), int(result.get_string('height'))))
		elif attr == 'fillcolor':
			var result = colorRegex.search(attributes[attr])
		elif attr == 'id':
			var id = attributes[attr]
			if elementsByID.has(id):
				print("Warning: duplicate ID %s" % id)
			elementsByID[id] = element
		else:
			print("%s = '%s'" % [attr, attributes[attr]])

