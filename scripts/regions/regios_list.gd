extends VBoxContainer

var items_in_list = [] # button of each region
var selected_region_to_load

func _on_selected(btn):
	for item in items_in_list:
		if item != btn:
			item.pressed = false
		else:
			# If we clicked on the same button, keep it toggled
			# Something must be always toggled
			btn.pressed = true
	self.selected_region_to_load = btn.text

func _ready():
	build_regions_list()


func build_regions_list():
	# This function should create list of all available regions and
	# populate the scroll container
	var dirs = Utils.dir_contents(Core.game_dir + '/Regions/').dirs
	var select_first_item = true
	for dir in dirs:
		if dir != "." and dir != "..":
			Logger.info(dir)
			var btn = Button.new()
			btn.text = dir
			btn.toggle_mode = true
			if select_first_item:
				btn.pressed = true
				select_first_item = false
				self.selected_region_to_load = btn.text
			items_in_list.append(btn)
			btn.connect("pressed", self, "_on_selected", [btn])
			self.add_child(btn)


func _on_load_btn_pressed():
	Core.current_region_name = selected_region_to_load
	self.get_node("../../../../").load_region()
	
