extends GZWin
class_name GZWinBtn 

# Texture order:
# 0. disabled
# 1. normal
# 2. pressed
# 3. hover 

enum ButtonState {
	DISABLED = 0,
	NORMAL = 1,
	PRESSED = 2,
	HOVER = 3,
	CHECKBOX_DISABLED = 6,
	CHECKBOX_PRESSED = 4,
	CHECKBOX_HOVER = 2,
}

enum ButtonStyle {
	STANDARD = 0,
	RADIOCHECK,
	TOGGLE
}

signal clicked
signal toggled_on
signal toggled_off
signal checked
signal unchecked

var state = 0
# Checkboxes and radio buttons seem to have eight states
var textures : Array = [null, null, null, null, null, null, null, null]
var N_SUBTEXTURES : int = 4
var style =ButtonStyle.STANDARD
var is_toggled : bool = false
var is_hovered : bool = false
var is_pressed : bool = false
var is_checked : bool = false
var is_disabled : bool = false

func _init(attributes : Dictionary):
	super(attributes)
	var style = attributes.get('style', 'standard')
	match style:
		"standard":
			self.style = ButtonStyle.STANDARD
			N_SUBTEXTURES = 4
		"radiocheck":
			self.style = ButtonStyle.RADIOCHECK
			N_SUBTEXTURES = 8
		"toggle":
			self.style = ButtonStyle.TOGGLE
			N_SUBTEXTURES = 4
	if 'image' in attributes:
		set_texture(attributes['image'].get_as_texture())
	if 'imagerect' in attributes:
		print("Imagerect", attributes['imagerect'])
	update_state()

func set_texture(texture : Texture2D):
	set_size(Vector2(texture.get_width() / N_SUBTEXTURES, texture.get_height()))
	for i in N_SUBTEXTURES:
		textures[i] = get_cropped_texture(texture, Rect2(i * texture.get_width() / N_SUBTEXTURES, 0, texture.get_width() / N_SUBTEXTURES, texture.get_height()))

func get_cropped_texture(texture : Texture2D, region : Rect2):
	var atlas_texture = AtlasTexture.new()
	atlas_texture.set_atlas(texture)
	atlas_texture.set_region_enabled(region)
	return atlas_texture

func get_minimum_size():
	return get_size()

func _draw():
	draw_texture(self.textures[self.state], Vector2())

func update_state():
	if self.style == ButtonStyle.STANDARD or self.style == ButtonStyle.TOGGLE:
		if is_disabled:
			self.state = ButtonState.DISABLED
		elif is_pressed or is_toggled:
			self.state = ButtonState.PRESSED
		elif is_hovered:
			self.state = ButtonState.HOVER
		else:
			self.state = ButtonState.NORMAL
	else:
		self.state = 0
		if not is_checked:
			self.state += 1
		if is_disabled:
			self.state += ButtonState.CHECKBOX_DISABLED
		elif is_pressed:
			self.state += ButtonState.CHECKBOX_PRESSED
		elif is_hovered:
			self.state += ButtonState.CHECKBOX_HOVER
	update()

func _gui_input(event):
	if is_disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressed = true
			if self.style == ButtonStyle.RADIOCHECK:
				is_checked = not is_checked
				if is_checked:
					emit_signal('checked')
				else:
					emit_signal('unchecked')
			elif self.style == ButtonStyle.TOGGLE:
				is_toggled = not is_toggled
				if is_toggled:
					emit_signal('toggled_on')
				else:
					emit_signal('toggled_off')
			else:
				emit_signal('clicked')
		else:
			is_pressed = false
		update_state()

func _notification(what):
	match what:
		NOTIFICATION_MOUSE_ENTER:
			if not is_disabled:
				is_hovered = true
			update_state()

		NOTIFICATION_MOUSE_EXIT:
			if not is_disabled:
				is_hovered = false
			update_state()

func set_state(state):
	self.state = state
	update()
