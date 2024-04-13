extends Node2D

var IMAGE_WIDTH = 16
var IMAGE_HEIGHT = 16
var IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT
var _pixels: Array[int] = []

var texture: Texture2D

func set_drawing(pixels: Array[int]):
	_pixels = pixels

# Called when the node enters the scene tree for the first time.
func _ready():
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	if _pixels.size() == IMAGE_SIZE:
		for h in range(IMAGE_HEIGHT):
			for w in range(IMAGE_WIDTH):
				if _pixels[h * IMAGE_WIDTH + w] == 1:
					image.set_pixel(w, h, Color.GRAY)
				else:
					image.set_pixel(w, h, Color.TRANSPARENT)
	else:
		printerr("Invalid image size received: ", _pixels.size())
	texture = ImageTexture.create_from_image(image)

func _create_unit(pos: Vector2):
	print("create unit at ", pos)
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	add_child(sprite)

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var pos: Vector2 = get_local_mouse_position()
			_create_unit(pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
