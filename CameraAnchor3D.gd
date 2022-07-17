extends KinematicBody

var zoom = 1
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
		print($Camera.project_position(Vector2(0.5, 0.5), 0.5))
	elif event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				self.zoom += 1
				if self.zoom > 5:
					self.zoom = 5
				$Camera.size = pow(2, (6 - self.zoom))*5
				get_parent().set_view(self.zoom)
			elif event.button_index == BUTTON_WHEEL_DOWN:
				self.zoom -= 1
				if self.zoom < 1:
					self.zoom = 1
				$Camera.size = pow(2, (6 - self.zoom))*5
				get_parent().set_view(self.zoom)

func _physics_process(_delta):
	self.move_and_slide(self.velocity)
