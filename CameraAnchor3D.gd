extends KinematicBody

var velocity = Vector3(0, 0, 0)

func _ready():
	pass

func _input(event):
	var viewport = self.get_viewport()
	var margin_w = viewport.size.x / 15
	var margin_h = viewport.size.y / 15
	var move_x = 0
	var move_z = 0
	# Should move one screen width every 5 seconds
	var move_vel = viewport.size.x / 30
	if event is InputEventMouseMotion:
		if event.position.x < margin_w:
			move_x = 1
		elif event.position.x > viewport.size.x - margin_w:
			move_x = -1
		else:
			move_x = 0

		if event.position.y < margin_h:
			move_z = 1
		elif event.position.y > viewport.size.y - margin_h:
			move_z = -1
		else:
			move_z = 0
		
		self.velocity = Vector3(move_x * move_vel, 0, move_z * move_vel)

func _physics_process(_delta):
	self.move_and_slide(self.velocity)
