extends GZWinText

func format_thousands(val):
	var res = "%d" % floor(val / 1000)
	var separator = " "
	while val >= 1000:
		res = "%s%s%03d" % [res, separator, (val % 1000)]
		val /= 1000
	return res

func _init(attributes).(attributes):
	self.name = "RegionNameDisplay"

func _ready():
	var population = get_node("/root/Region").total_population
	self.set_text(format_thousands(population))
