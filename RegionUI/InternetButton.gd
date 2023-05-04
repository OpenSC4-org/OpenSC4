extends GZWinBtn

func _init(attributes,attributes):
	self.name = "InternetButton"
	self.connect("clicked",Callable(self,"_on_clicked"))

func _on_clicked():
	OS.shell_open("https://github.com/OpenSC4-org/OpenSC4")
