extends KinematicBody

var zoom = 1
var zoom_list = [292, 146, 73, 32, 16, 8]
var elevations = [60, 55, 50, 45, 45, 45]
var AZIMUTH = deg2rad(67.5)
var boot = true
var velocity = Vector3(0, 0, 0)
var hold_r = []

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
			elif event.button_index == BUTTON_RIGHT:
				if len(hold_r) == 0:
					hold_r = [event.position.x, event.position.y]
			elif event.button_index == BUTTON_WHEEL_DOWN:
				self.zoom -= 1
				if self.zoom < 1:
					self.zoom = 1
				$Camera.size = zoom_list[self.zoom-1]
				_set_view()
		if not event.is_pressed():
			if event.button_index == BUTTON_RIGHT:
				hold_r = []

func _physics_process(_delta):
	self.move_and_slide(self.velocity)

func _set_view():
	# Elevation angle, Azimuth is a class var since it doesn't change
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
	self.get_parent().get_node("Spatial/Sun").transform.origin = Vector3(500, 200, -50)
	self.get_parent().get_node("Spatial/Sun").look_at(Vector3(0.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0))
	var mat = self.get_parent().get_node("Spatial/Terrain").get_material_override()
	mat.set_shader_param("zoom", zoom)
	mat.set_shader_param("tiling_factor", zoom)
	self.get_parent().get_node("Spatial/Terrain").set_material_override(mat)
	var mat_e = self.get_parent().get_node("Spatial/Border").get_material_override()
	mat_e.set_shader_param("zoom", zoom)
	mat_e.set_shader_param("tiling_factor", zoom)
	self.get_parent().get_node("Spatial/Border").set_material_override(mat_e)
	var mat_w = self.get_parent().get_node("Spatial/WaterPlane").get_material_override()
	mat_w.set_shader_param("zoom", zoom)
	mat_w.set_shader_param("tiling_factor", zoom)
	self.get_parent().get_node("Spatial/WaterPlane").set_material_override(mat_w)
	
