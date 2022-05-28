extends ItemList


func _ready():
	self.connect("item_activated", self, "on_item_activated")
	pass

func on_item_activated(item_index: int):
	var img = get_item_icon(item_index).get_data()
	var name = get_item_text(item_index)
	# Save to the disk
	img.save_png("tmp/%s.png" % name)
