extends GZWinBtn

func _init(attributes : Dictionary).(attributes):
	self.name="TopBarSettingsButton"
	self.connect("toggled_on", self, "_on_toggled_on")
	self.connect("toggled_off", self, "_on_toggled_off")

func _on_toggled_on():
	$"../../TopBarSettingsMenu".set_visible(true)

func _on_toggled_off():
	$"../../TopBarSettingsMenu".set_visible(false) 