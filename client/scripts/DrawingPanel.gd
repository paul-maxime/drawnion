extends PanelContainer

var IMAGE_WIDTH = 16
var IMAGE_HEIGHT = 16
var IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT

var MIN_PIXELS = 30
var MAX_PIXELS = 110

var pixels: Array[int] = []
var center

var _has_valid_count = false

# Called when the node enters the scene tree for the first time.
func _ready():
	center = Vector2(float(IMAGE_WIDTH - 1) / 2, float(IMAGE_HEIGHT - 1) / 2)
	pixels.resize(IMAGE_SIZE)
	pixels.fill(0)
	_update_count_label()

func set_pixel(pos: Vector2i, isDrawn: bool):
	if pos.x < 0 or pos.y < 0 or pos.x >= IMAGE_WIDTH or pos.y >= IMAGE_HEIGHT:
		return
	if center.distance_to(pos) > float(IMAGE_WIDTH) / 2:
		return
	pixels[pos.x + pos.y * IMAGE_WIDTH] = 1 if isDrawn else 0
	queue_redraw()

var last_mouse_pixel = null

func get_pixel_from_mouse():
	var pos = get_local_mouse_position()
	return Vector2i(pos.x * IMAGE_WIDTH / size.x, pos.y * IMAGE_HEIGHT / size.y)

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var pixel_pos = get_pixel_from_mouse()
			last_mouse_pixel = pixel_pos
			set_pixel(pixel_pos, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var pixel_pos = get_pixel_from_mouse()
			if pixel_pos != last_mouse_pixel:
				last_mouse_pixel = pixel_pos
				set_pixel(pixel_pos, Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	_update_count_label()

func _draw():
	var ratio = Vector2(size.x / IMAGE_WIDTH, size.y / IMAGE_HEIGHT)
	for h in range(IMAGE_HEIGHT):
		for w in range(IMAGE_WIDTH):
			var point = Vector2(w, h)
			if center.distance_to(point) > float(IMAGE_WIDTH) / 2:
				pass
			elif pixels[h * IMAGE_WIDTH + w] == 0:
				draw_rect(Rect2(w * ratio.x, h * ratio.y, ratio.x, ratio.y), Color.GRAY)
			else:
				draw_rect(Rect2(w * ratio.x, h * ratio.y, ratio.x, ratio.y), Color.WHITE)

func _black_pixels_count():
	var count = 0
	for h in range(IMAGE_HEIGHT):
		for w in range(IMAGE_WIDTH):
			if pixels[h * IMAGE_WIDTH + w] == 1:
				count += 1
	return count

func _update_count_label():
	var black_pixels = _black_pixels_count()
	if black_pixels < MIN_PIXELS:
		var delta = MIN_PIXELS - black_pixels
		$"../Label".text = "Summon your minion!\nDraw %d more pixels." % delta
		_has_valid_count = false
		$"../ProgressBar".value = black_pixels
		$"../ProgressBar".max_value = MIN_PIXELS
	elif black_pixels > MAX_PIXELS:
		var delta = black_pixels - MAX_PIXELS
		$"../Label".text = "Summon your minion!\nDraw %d less pixels." % delta
		_has_valid_count = false
		$"../ProgressBar".value = 208 - black_pixels
		$"../ProgressBar".max_value = 208 - MAX_PIXELS
	else:
		$"../Label".text = "Summon your minion!"
		_has_valid_count = true
		$"../ProgressBar".value = 100
		$"../ProgressBar".max_value = 100

func _on_start_game_pressed():
	if not _has_valid_count:
		return
	var arena = load("res://scenes/Arena.tscn").instantiate()
	arena.set_drawing(pixels)
	get_tree().root.add_child(arena)
	get_node("/root/Drawing").queue_free()
