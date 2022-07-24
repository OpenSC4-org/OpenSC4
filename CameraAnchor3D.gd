extends KinematicBody

var zoom = 1
var zoom_list = [292, 146, 73, 32, 16, 8]
var elevations = [60, 55, 50, 45, 45, 45]
var AZIMUTH = deg2rad(67.5)
var boot = true
var velocity = Vector3(0, 0, 0)

func _ready():
	_set_view()
	pass

func _input(event):
	var viewport = self.get_viewport()
	var margin_w = viewport.size.x / 15
	var margin_h = viewport.size.y / 15
	var move = Vector3(0, 0, 0)
	var camera_forward = $Camera.transform.basis.y
	var camera_left = $Camera.transform.basis.x
	# Should move one screen width every 5 seconds
	var move_vel = $Camera.size
	if event is InputEventMouseMotion:
		if event.position.x < margin_w:
			move -= camera_left
		elif event.position.x > viewport.size.x - margin_w:
			move += camera_left

		if event.position.y < margin_h:
			move += camera_forward
		elif event.position.y > viewport.size.y - margin_h:
			move -= camera_forward
		
		self.velocity = move.normalized() * move_vel
		#print($Camera.project_position(Vector2(0.5, 0.5), 0.5))
	elif event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				self.zoom += 1
				if self.zoom > 6:
					self.zoom = 6
				$Camera.size = zoom_list[self.zoom-1]
				_set_view()
			elif event.button_index == BUTTON_WHEEL_DOWN:
				self.zoom -= 1
				if self.zoom < 1:
					self.zoom = 1
				$Camera.size = zoom_list[self.zoom-1]
				_set_view()

func _physics_process(_delta):
	self.move_and_slide(self.velocity)

func _set_view():
	"""these calculations are for a left handed axis system, godot uses a right handed system
	in order to convert from right handed to left handed you can reverse the direction of one or all axis
	RH: y		LH: y		   0,0___1,0
		|_x			|_x		  /	     /
	   / 		   /		 /		/
	  z   		 -z			0,1___1,1
	with x,z ranging from 0,0:topleft to n,n:bottom right in rotation 0
	it basically means their values have a reversed effect 
	to deal with this i can set their local transforms to -1, -1
	but with the handedness being swapped I'd only need to tranform one of them
	
	These calculations are set up for y=up projection
	this is done by swapping the y and z inputs
	"""
	var El = deg2rad(elevations[zoom-1])
	
	# exposure angles D and E
	var D = atan( (cos(El)) / (tan(AZIMUTH)) )
	var E = atan( (cos(El)) * (tan(AZIMUTH)) )
	# axis shrink factors 
	var Sx = sin(AZIMUTH) / cos(D)
	var Sz = cos(AZIMUTH) / cos(E)
	var Sy = sin(El)
	# range divisor, not sure why its needed
	var rng_d = 1
	# setting up the transform
	var v_trans = transform
	v_trans.basis.x = Vector3(-(Sx*cos(D))/rng_d, 0.0, Sx*sin(D)/rng_d)
	v_trans.basis.y = Vector3(0.0, -1.0, Sy/rng_d)
	v_trans.basis.z = Vector3((Sz*cos(E))/rng_d, 1.0, (Sz*sin(E))/rng_d)
	v_trans.origin = Vector3(0.0, 0.0, 0.0)
	self.get_parent().get_node("Spatial").transform = v_trans
	#if elevations[zoom-1] == 45:
	print("debug", v_trans, ",\n get:", $Camera.transform)
