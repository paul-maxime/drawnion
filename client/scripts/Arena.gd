extends Node

var entity_scene: PackedScene = preload ("res://scenes/TestEntity.tscn")

var _rng = RandomNumberGenerator.new()
var _units = {};

func _ready():
	$Network.game_joined.connect(_on_game_joined)
	$Network.entity_summoned.connect(_on_entity_summoned)
	$Network.entity_moved.connect(_on_entity_moved)
	$Network.entity_damaged.connect(_on_entity_damaged)
	$Network.entity_despawned.connect(_on_entity_despawned)

func _process(delta):
	for id in _units:
		var unit = _units[id]
		if unit.position_target != unit.entity.position:
			unit.moving_time += delta * 10
			unit.entity.position = unit.position_start.lerp(unit.position_target, unit.moving_time)

func _on_game_joined(player_id: int):
	print("Joined the game, player id: %d" % [player_id])
	$Network.sendSummon(_rng.randi() % 512, 0 if player_id % 2 == 0 else 511, (_rng.randi() % 4 + 1) * 16)

func _on_entity_summoned(unit_id: int, owner_id: int, x: int, y: int, size: int):
	print("Entity %d summoned at (%d, %d), owner %d, size %d" % [unit_id, x, y, owner_id, size])
	var entity: Node2D = entity_scene.instantiate()
	entity.position = Vector2(x, y)
	entity.set_entity_size(size)
	var unit = {}
	unit.entity = entity
	unit.position_start = entity.position
	unit.position_target = entity.position
	unit.moving_time = 0
	_units[unit_id] = unit
	$Entities.add_child(entity)

func _on_entity_moved(unit_id: int, x: int, y: int):
	print("Entity %d moved to (%d, %d)" % [unit_id, x, y])
	var unit = _units.get(unit_id)
	if unit == null:
		print("Unknown entity")
		return
	unit.position_start = unit.entity.position
	unit.position_target = Vector2(x, y)
	unit.moving_time = 0

func _on_entity_damaged(unit_id: int, attacker_id: int, new_size: int):
	print("Entity %d attacked by %d, new size %d" % [unit_id, attacker_id, new_size])
	var unit = _units.get(unit_id)
	if unit == null:
		print("Unknown entity")
		return
	unit.entity.set_entity_size(new_size)

func _on_entity_despawned(unit_id: int):
	print("Entity %d despawned" % [unit_id])
	var unit = _units.get(unit_id)
	if unit == null:
		print("Unknown entity")
		return
	unit.entity.queue_free()
	unit.erase(unit_id)

# extends Node2D

# var IMAGE_WIDTH = 16
# var IMAGE_HEIGHT = 16
# var IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT
# var _pixels: Array[int] = []

# var texture: Texture2D

# func set_drawing(pixels: Array[int]):
# 	_pixels = pixels

# # Called when the node enters the scene tree for the first time.
# func _ready():
# 	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
# 	if _pixels.size() == IMAGE_SIZE:
# 		for h in range(IMAGE_HEIGHT):
# 			for w in range(IMAGE_WIDTH):
# 				if _pixels[h * IMAGE_WIDTH + w] == 1:
# 					image.set_pixel(w, h, Color.GRAY)
# 				else:
# 					image.set_pixel(w, h, Color.TRANSPARENT)
# 	else:
# 		printerr("Invalid image size received: ", _pixels.size())
# 	texture = ImageTexture.create_from_image(image)

# func _create_unit(pos: Vector2):
# 	print("create unit at ", pos)
# 	var sprite = Sprite2D.new()
# 	sprite.texture = texture
# 	sprite.position = pos
# 	add_child(sprite)

# func _input(event):
# 	if event is InputEventMouseButton:
# 		if event.is_pressed() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
# 			var pos: Vector2 = get_local_mouse_position()
# 			_create_unit(pos)

# # Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(_delta):
# 	pass
