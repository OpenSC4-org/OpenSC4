extends Node

const _PRINT_DEBUG: bool = true


func print_dict(dict, node:Node):
	if _PRINT_DEBUG:		
		for key in dict:
			print(key)
			for key2 in dict[key]:
				print("\t" + key2 + " = " + dict[key][key2])
