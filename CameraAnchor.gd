extends KinematicBody2D

var velocity = Vector2(0, 0)
var viewport = 0
var margin_w = 0
var margin_h = 0
var move = Vector2(0, 0)
var mouse_right_click_origin = Vector2(0, 0)
var mouse_position = Vector2(0, 0)

#Should move one screen width every 4 seconds
#var move_speed = viewport.size.x / 4
var move_speed = 16834 # just manually setting it idk

func _ready():
	pass

func _input(event):
	viewport = self.get_viewport()
	margin_w = viewport.size.x / 15
	margin_h = viewport.size.y / 15

	if event is InputEventMouseMotion:
		if event.position.x < margin_w:
			move.x = -1
		elif event.position.x > viewport.size.x - margin_w:
			move.x = 1
		
		if event.position.y < margin_h:
			move.y = -1
		elif event.position.y > viewport.size.y - margin_h:
			move.y = 1		
	
	if Input.is_action_pressed("camera_up"):
		move.y = -1
	elif Input.is_action_pressed("camera_down"):
		move.y = 1
	
	if Input.is_action_pressed("camera_left"):
		move.x = -1
	elif Input.is_action_pressed("camera_right"):
		move.x = 1
	
	# `normalized() * move_speed` so no fast diagonal movement
	self.velocity = move.normalized() * move_speed
	
	# reset variables
	move.x = 0
	move.y = 0

func right_click_movement():
	if Input.is_action_just_pressed("camera_right_click"):
		mouse_right_click_origin = get_local_mouse_position()
	
	if Input.is_action_pressed("camera_right_click"):
		mouse_position = get_local_mouse_position()
		move = mouse_position - mouse_right_click_origin
		
		self.velocity = move.normalized() * move_speed * move.length()/256
		
		move.x = 0
		move.y = 0

func _process(delta):
	right_click_movement()
	self.move_and_slide(self.velocity * delta)
