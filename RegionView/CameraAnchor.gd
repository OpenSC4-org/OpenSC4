extends KinematicBody2D

var velocity = Vector2(0, 0)

func _ready():
	pass

func _input(event):
	var viewport = self.get_viewport()
	var margin_w = viewport.size.x / 15
	var margin_h = viewport.size.y / 15
	var move_x = 0
	var move_y = 0
	# Should move one screen width every 4 seconds
	var move_vel = viewport.size.x / 4
	if event is InputEventMouseMotion:
		if event.position.x < margin_w:
			move_x = -1
		elif event.position.x > viewport.size.x - margin_w:
			move_x = 1
		else:
			move_x = 0

		if event.position.y < margin_h:
			move_y = -1
		elif event.position.y > viewport.size.y - margin_h:
			move_y = 1
		else:
			move_y = 0
		
		self.velocity = Vector2(move_x * move_vel, move_y * move_vel)

func _physics_process(_delta):
	var _notused = self.move_and_slide(self.velocity)
