extends GZWinGen 

func _init(attributes : Dictionary):
	super(attributes)
	self.set_anchors_preset(PRESET_TOP_RIGHT, true)
	self.name="TopBarSettingsMenu"
	self.visible = false