extends PanelContainer

var IMAGE_WIDTH = 16
var IMAGE_HEIGHT = 16
var IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT

var pixels: Array[int] = []
var arena_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	arena_scene = preload ("res://scenes/Arena.tscn")
	pixels.resize(IMAGE_SIZE)
	pixels.fill(0)

func set_pixel(pos: Vector2i, isDrawn: bool):
	if pos.x < 0 or pos.y < 0 or pos.x >= IMAGE_WIDTH or pos.y >= IMAGE_HEIGHT:
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

func _draw():
	var ratio = Vector2(size.x / IMAGE_WIDTH, size.y / IMAGE_HEIGHT)
	for h in range(IMAGE_HEIGHT):
		for w in range(IMAGE_WIDTH):
			if pixels[h * IMAGE_WIDTH + w] == 0:
				draw_rect(Rect2(w * ratio.x, h * ratio.y, ratio.x, ratio.y), Color.GRAY)
			else:
				draw_rect(Rect2(w * ratio.x, h * ratio.y, ratio.x, ratio.y), Color.WHITE)

func _pixel_ratio():
	var count = 0
	for h in range(IMAGE_HEIGHT):
		for w in range(IMAGE_WIDTH):
			if pixels[h * IMAGE_WIDTH + w] == 1:
				count += 1
	return float(count) / (IMAGE_WIDTH * IMAGE_HEIGHT)

func _on_start_game_pressed():
	if _pixel_ratio() < 0.33:
		# TODO print error on label control
		return
	var arena = arena_scene.instantiate()
	arena.set_drawing(pixels)
	get_tree().root.add_child(arena)
	get_node("/root/Drawing").queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
