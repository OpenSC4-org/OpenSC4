tool
extends EditorPlugin
class_name DBPFPlugin

func _enter_tree():
	self.add_custom_type('DBPF', 'Resource', load("res://addons/dbpf/DBPF.gd"), load("res://addons/dbpf/dbpf.png"))

func _exit_tree():
	pass