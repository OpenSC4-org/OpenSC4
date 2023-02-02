extends KinematicBody2D

var velocity = Vector2(0, 0)
var viewport = 0
var margin_w = 0
var margin_h = 0
var move = Vector2(0, 0)
#dk Should move one screen width every 4 seconds
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
			move.x = -move_speed
		elif event.position.x > viewport.size.x - margin_w:
			move.x = move_speed

		if event.position.y < margin_h:
			move.y = -move_speed
		elif event.position.y > viewport.size.y - margin_h:
			move.y = move_speed
	if Input.is_action_pressed("camera_up"):
		move.y = -move_speed
	if Input.is_action_pressed("camera_down"):
		move.y = move_speed
	if Input.is_action_pressed("camera_left"):
		move.x = -move_speed
	if Input.is_action_pressed("camera_right"):
		move.x = move_speed
	
	# `normalized() * move_speed` so no fast diagonal movement
	self.velocity = Vector2(move.x, move.y).normalized() * move_speed
	
	# reset variables
	move.x = 0
	move.y = 0

func _process(delta):
	self.move_and_slide(self.velocity * delta)
