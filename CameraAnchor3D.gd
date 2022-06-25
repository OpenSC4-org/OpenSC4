extends KinematicBody

var velocity = Vector3(0, 0, 0)

func _ready():
	pass

func _input(event):
	var viewport = self.get_viewport()
	var margin_w = viewport.size.x / 15
	var margin_h = viewport.size.y / 15
	var move = Vector3(0, 0, 0)
	var camera_forward = get_global_transform().basis.z
	var camera_left = get_global_transform().basis.x
	# Should move one screen width every 5 seconds
	var move_vel = $Camera.size
	if event is InputEventMouseMotion:
		if event.position.x < margin_w:
			move += camera_left
		elif event.position.x > viewport.size.x - margin_w:
			move -= camera_left

		if event.position.y < margin_h:
			move += camera_forward
		elif event.position.y > viewport.size.y - margin_h:
			move -= camera_forward
		
		self.velocity = move.normalized() * move_vel
	elif event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				$Camera.size /= 2
			elif event.button_index == BUTTON_WHEEL_DOWN:
				$Camera.size *= 2

func _physics_process(_delta):
	self.move_and_slide(self.velocity)
