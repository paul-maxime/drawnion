extends Node2D

var entity_scene: PackedScene = preload ("res://scenes/TestEntity.tscn")

var _rng = RandomNumberGenerator.new()
var _units = {};

var IMAGE_WIDTH = 16
var IMAGE_HEIGHT = 16
var IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT

var server_width = 0
var server_height = 0

var _avatar: Array[int]
var _player_id
var _avatars = {}

var _neutral_color = Color("DDDDDD")
var _colors = [
    Color("F40404"),
    Color("0C48CC"),
    Color("2CB494"),
    Color("88409C"),
    Color("F88C14"),
    Color("703014"),
    Color("CCE0D0"),
    Color("FCFC38"),
    Color("088008"),
    Color("FCFC7C"),
    Color("ECC4B0"),
    Color("4068D4"),
]

var _avatar_shader
var _noise_texture

func set_drawing(avatar: Array[int]):
	_avatar = avatar

func _ready():
	_avatar_shader = preload ("res://shaders/unit.gdshader")
	_noise_texture = preload ("res://assets/images/noise/Abstract_Noise_024-128x128.png")
	_create_avatar(0, [
		0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0,
		0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0,
		0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0,
		0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0,
		0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0,
		1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1,
		1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, # hello there
		1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1,
		0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0,
		0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0,
		0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0,
		0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0,
		0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
	])
	$Network.game_joined.connect(_on_game_joined)
	$Network.player_avatar_received.connect(_on_avatar_received)
	$Network.entity_summoned.connect(_on_entity_summoned)
	$Network.entity_moved.connect(_on_entity_moved)
	$Network.entity_damaged.connect(_on_entity_damaged)
	$Network.entity_despawned.connect(_on_entity_despawned)
	$Network.network_closed.connect(_on_network_closed)

func _process(delta):
	for id in _units:
		var unit = _units[id]
		if unit.position_target != unit.entity.position:
			unit.moving_time += delta * 10
			unit.entity.position = unit.position_start.lerp(unit.position_target, min(1, unit.moving_time))

func _input(event):
	if server_width == 0:
		# haven't received map size yet
		return
	if event is InputEventMouseButton:
		if event.is_pressed() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var pos: Vector2 = get_local_mouse_position()
			var spawn_pos = _closest_server_spawn_from_pos(pos)
			print(spawn_pos)
			var size = (_rng.randi() % 4 + 1) * 16;
			var element = _rng.randi() % 3 + 1;
			$Network.sendSummon(spawn_pos.x, spawn_pos.y, size, element)

func _client_pos_to_server_pos(pos: Vector2):
		return Vector2((pos.x - $FightingZone.position.x) / $FightingZone.size.x * (server_width - 1), (pos.y - $FightingZone.position.y) / $FightingZone.size.y * (server_height - 1))

func _server_pos_to_client_pos(pos: Vector2):
		return Vector2(pos.x / (server_width - 1) * $FightingZone.size.x + $FightingZone.position.x, pos.y / (server_height - 1) * $FightingZone.size.y + $FightingZone.position.y)

func _closest_server_spawn_from_pos(pos: Vector2):
	var client_pos = _closest_client_spawn_from_pos(pos)
	var server_pos = _client_pos_to_server_pos(client_pos)
	return server_pos

func _closest_client_spawn_from_pos(pos: Vector2):
	if pos.x < 0:
		pos.x = 0
	elif pos.x >= $FightingZone.size.x:
		pos.x = $FightingZone.size.x - 1
	if pos.y < 0:
		pos.y = 0
	elif pos.y >= $FightingZone.size.y:
		pos.y = $FightingZone.size.y - 1
	var distance_bot = pos.distance_to(Vector2(pos.x, $FightingZone.position.y))
	var distance_top = pos.distance_to(Vector2(pos.x, $FightingZone.position.y + $FightingZone.size.y))
	var distance_y = min(distance_top, distance_bot)
	var distance_left = pos.distance_to(Vector2($FightingZone.position.x, pos.y))
	var distance_right = pos.distance_to(Vector2($FightingZone.position.x + $FightingZone.size.x, pos.y))
	var distance_x = min(distance_left, distance_right)
	if distance_x < distance_y:
		if distance_left < distance_right:
			return Vector2($FightingZone.position.x, pos.y)
		else:
			return Vector2($FightingZone.position.x + $FightingZone.size.x, pos.y)
	else:
		if distance_bot < distance_top:
			return Vector2(pos.x, $FightingZone.position.y)
		else:
			return Vector2(pos.x, $FightingZone.position.y + $FightingZone.size.y)

func _on_game_joined(player_id: int, map_width: int, map_height: int):
	print("Joined the game, player id: %d" % [player_id])
	_player_id = player_id
	server_width = map_width
	server_height = map_height
	if _avatar == null or _avatar.is_empty():
		_avatar = []
		_avatar.resize(IMAGE_SIZE)
		_avatar.fill(1)
	$Network.sendAvatar(_avatar)

func _create_avatar(player_id: int, pixels: Array):
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	if pixels.size() == IMAGE_SIZE:
		for h in range(IMAGE_HEIGHT):
			for w in range(IMAGE_WIDTH):
				if pixels[h * IMAGE_WIDTH + w] == 1:
					image.set_pixel(w, h, Color.GRAY)
				else:
					image.set_pixel(w, h, Color.TRANSPARENT)
	else:
		printerr("Invalid image size received: ", pixels.size())
	print("avatar received: ", player_id)
	var texture = ImageTexture.create_from_image(image)
	_avatars[player_id] = texture

func _on_avatar_received(player_id: int, pixels: Array):
	_create_avatar(player_id, pixels)

func _on_entity_summoned(unit_id: int, owner_id: int, x: int, y: int, size: int, element: int):
	print("Entity %d summoned at (%d, %d), owner %d, size %d, type %d" % [unit_id, x, y, owner_id, size, element])
	if _avatars.get(owner_id) == null:
		printerr("Unknown owner ID for entity ", owner_id)
		return
	var entity: Node2D = entity_scene.instantiate()
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	var color = _get_color_for_player(owner_id)
	entity.circle_color = Color(color.r, color.g, color.b, 0.3)
	sprite.texture = _avatars[owner_id]
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = _avatar_shader
	sprite.material.set_shader_parameter("inside_color", Color(color.r, color.g, color.b, 0.7))
	sprite.material.set_shader_parameter("noise_texture", _noise_texture)
	sprite.material.set_shader_parameter("timeScaleFactor", 1.0)
	#sprite.material.set_shader_parameter("width", 0.1)
	if element == 1:
		sprite.material.set_shader_parameter("line_color", Color("#36db3e")) # feuille
	elif element == 2:
		sprite.material.set_shader_parameter("line_color", Color("#ff2e00")) # feu
	elif element == 3:
		sprite.material.set_shader_parameter("line_color", Color("#20aad9")) # eau
	var ratio = $FightingZone.size.x / server_width
	entity.position = _server_pos_to_client_pos(Vector2(x, y))
	entity.scale = Vector2(float(size) / IMAGE_WIDTH * ratio, float(size) / IMAGE_HEIGHT * ratio)
	entity.add_child(sprite)

	var unit = {}
	unit.entity = entity
	unit.position_start = entity.position
	unit.position_target = entity.position
	unit.moving_time = 0
	_units[unit_id] = unit
	$Entities.add_child(entity)

func _get_color_for_player(player_id: int):
	if player_id == 0:
		return _neutral_color
	return _colors[player_id % _colors.size()]

func _on_entity_moved(unit_id: int, x: int, y: int):
	#print("Entity %d moved to (%d, %d)" % [unit_id, x, y])
	var unit = _units.get(unit_id)
	if unit == null:
		print("Unknown entity")
		return
	unit.position_start = unit.entity.position
	unit.position_target = _server_pos_to_client_pos(Vector2(x, y))
	unit.moving_time = 0

func _on_entity_damaged(unit_id: int, attacker_id: int, new_size: int):
	#print("Entity %d attacked by %d, new size %d" % [unit_id, attacker_id, new_size])
	var unit = _units.get(unit_id)
	if unit == null:
		print("Unknown entity")
		return
	var ratio = $FightingZone.size.x / server_width
	unit.entity.scale = Vector2(float(new_size) / IMAGE_WIDTH * ratio, float(new_size) / IMAGE_HEIGHT * ratio)

func _on_entity_despawned(unit_id: int):
	#print("Entity %d despawned" % [unit_id])
	var unit = _units.get(unit_id)
	if unit == null:
		print("Unknown entity")
		return
	unit.entity.explode_and_die()
	_units.erase(unit_id)

func _on_network_closed():
	var drawing = load("res://scenes/Drawing.tscn").instantiate()
	get_tree().root.add_child(drawing)
	queue_free()
