extends KinematicBody

var zoom = 1
var zoom_list = [292, 146, 73, 32, 16, 8]
var elevations = [60, 55, 50, 45, 45, 45]
var AZIMUTH = deg2rad(67.5)
var rotated = 2
var boot = true
var velocity = Vector3(0, 0, 0)
var hold_r = []

func _ready():
	self.transform.origin = Vector3(self.transform.origin.x, get_parent().WATER_HEIGHT, self.transform.origin.z)
	_set_view()
	$Camera.set_znear(-200.0)
	pass

func _input(event):
	var viewport = self.get_viewport()
	var margin_w = viewport.size.x / 15
	var margin_h = viewport.size.y / 15
	var move = Vector3(0, 0, 0)
	var camera_forward = Vector3(self.transform.basis.z.x, 0, self.transform.basis.z.z)
	var camera_left = Vector3(self.transform.basis.x.x, 0, self.transform.basis.x.z)
	
	# Should move one screen width every 5 seconds
	var move_vel = $Camera.size
	if event is InputEventMouseMotion:
		if event.position.x < margin_w:
			move -= camera_left
		elif event.position.x > viewport.size.x - margin_w:
			move += camera_left

		if event.position.y < margin_h:
			move -= camera_forward
		elif event.position.y > viewport.size.y - margin_h:
			move += camera_forward
		
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
	elif event is InputEventKey:
		if event.pressed and event.scancode == KEY_PAGEUP:
			rotated = (rotated + 1)%4
			var rot = round(((rotated*(PI/2)) + get_node("../Spatial").rotation.y) / (PI/2))*(PI/2)
			var rot_trans = get_node("../Spatial").transform.rotated(Vector3(0,1,0), rot)
			get_node("../Spatial").set_transform(rot_trans)
			var old = self.transform.origin
			self.transform.origin = Vector3(-old.z, old.y, old.x)
		elif event.pressed and event.scancode == KEY_PAGEDOWN:
			rotated = ((rotated-1)+4)%4
			var rot = round(((rotated*(PI/2)) + get_node("../Spatial").rotation.y) / (PI/2))*(PI/2)
			var rot_trans = get_node("../Spatial").transform.rotated(Vector3(0,1,0), rot)
			get_node("../Spatial").set_transform(rot_trans)
			var old = self.transform.origin
			self.transform.origin = Vector3(old.z, old.y, -old.x)
func _physics_process(_delta):
	var _unused = self.move_and_slide(self.velocity)

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
	v_trans.basis.x = Vector3((Sx*cos(D))/rng_d, 	0.0, 		Sx*sin(D)/rng_d)
	v_trans.basis.y = Vector3(0.0, 					1.0, 		Sy/rng_d)
	v_trans.basis.z = Vector3(-(Sz*cos(E))/rng_d, 	-1.0, 		(Sz*sin(E))/rng_d)
	v_trans = v_trans.inverse()
	v_trans.origin = self.transform.origin
	self.transform = v_trans
	#print("in", v_trans, "\ncm", self.get_node("Camera").transform)
	
	# set sun location
	self.get_node("../Sun").transform.origin = Vector3(-50, 30, 20)
	self.get_node("../Sun").look_at(Vector3(0.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0))
	
	# set zoom related uniforms for shaders
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
	
