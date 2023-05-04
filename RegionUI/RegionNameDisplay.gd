extends GZWinText

func _init(attributes,attributes):
	self.name = "RegionNameDisplay"

func _ready():
	self.set_text(get_node("/root/Region").REGION_NAME)
