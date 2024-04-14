extends Node2D

var entity_scene: PackedScene = preload ("res://scenes/TestEntity.tscn")

var _rng = RandomNumberGenerator.new()
var _units = {};

var IMAGE_WIDTH = 16
var IMAGE_HEIGHT = 16
var IMAGE_SIZE = IMAGE_WIDTH * IMAGE_HEIGHT

var server_width
var server_height

var _avatar: Array[int]
var _player_id
var _avatars = {}
var _colors = {}

var _avatar_shader

func set_drawing(avatar: Array[int]):
	_avatar = avatar

func _ready():
	_avatar_shader = preload ("res://shaders/unit.gdshader")
	_create_avatar(0,
		[0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0] # hello there
	)
	_colors[0] = Color(0.8, 0.8, 0.8, 0.3)
	$Network.game_joined.connect(_on_game_joined)
	$Network.player_avatar_received.connect(_on_avatar_received)
	$Network.entity_summoned.connect(_on_entity_summoned)
	$Network.entity_moved.connect(_on_entity_moved)
	$Network.entity_damaged.connect(_on_entity_damaged)
	$Network.entity_despawned.connect(_on_entity_despawned)

func _process(delta):
	for id in _units:
		var unit = _units[id]
		if unit.position_target != unit.entity.position:
			unit.moving_time += delta * 10
			unit.entity.position = unit.position_start.lerp(unit.position_target, min(1, unit.moving_time))

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var pos: Vector2 = get_local_mouse_position()
			var spawn_pos = _closest_server_spawn_from_pos(pos)
			print(spawn_pos)
			var size = (_rng.randi() % 4 + 1) * 16;
			var element = _rng.randi() % 3 + 1;
			$Network.sendSummon(spawn_pos.x, spawn_pos.y, size, element)

func _client_pos_to_server_pos(pos: Vector2):
		print("(", pos.x, " - ", $FightingZone.position.x, ") / ", $FightingZone.scale.x, " * ", server_width)
		return Vector2((pos.x - $FightingZone.position.x) / $FightingZone.scale.x * (server_width - 1), (pos.y - $FightingZone.position.y) / $FightingZone.scale.y * (server_height - 1))

func _server_pos_to_client_pos(pos: Vector2):
		return Vector2(pos.x / (server_width - 1) * $FightingZone.scale.x + $FightingZone.position.x, pos.y / (server_height - 1) * $FightingZone.scale.y + $FightingZone.position.y)

func _closest_server_spawn_from_pos(pos: Vector2):
	print("click ", pos)
	var client_pos = _closest_client_spawn_from_pos(pos)
	print("client ", client_pos)
	var server_pos = _client_pos_to_server_pos(client_pos)
	print("server ", server_pos)
	return server_pos

func _closest_client_spawn_from_pos(pos: Vector2):
	var distance_bot = pos.distance_to(Vector2(pos.x, $FightingZone.position.y))
	var distance_top = pos.distance_to(Vector2(pos.x, $FightingZone.position.y + $FightingZone.scale.y))
	var distance_y = min(distance_top, distance_bot)
	var distance_left = pos.distance_to(Vector2($FightingZone.position.x, pos.y))
	var distance_right = pos.distance_to(Vector2($FightingZone.position.x + $FightingZone.scale.x, pos.y))
	var distance_x = min(distance_left, distance_right)
	if distance_x < distance_y:
		if distance_left < distance_right:
			return Vector2($FightingZone.position.x, pos.y)
		else:
			return Vector2($FightingZone.position.x + $FightingZone.scale.x, pos.y)
	else:
		if distance_bot < distance_top:
			return Vector2(pos.x, $FightingZone.position.y)
		else:
			return Vector2(pos.x, $FightingZone.position.y + $FightingZone.scale.y)

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
	_colors[player_id] = Color.from_hsv(randf_range(0, 1), 1, 1, 0.3)

func _on_avatar_received(player_id: int, pixels: Array):
	_create_avatar(player_id, pixels)

func _on_entity_summoned(unit_id: int, owner_id: int, x: int, y: int, size: int, _element: int):
	print("Entity %d summoned at (%d, %d), owner %d, size %d" % [unit_id, x, y, owner_id, size])
	if _avatars.get(owner_id) == null:
		printerr("Unknown owner ID for entity ", owner_id)
		return
	var entity: Node2D = entity_scene.instantiate()
	var sprite = Sprite2D.new()
	var color = _colors[owner_id]
	entity.circle_color = color
	sprite.texture = _avatars[owner_id]
	sprite.material = ShaderMaterial.new()
	sprite.material.set_shader_parameter("line_color", Color(color.r, color.g, color.b, 0.7))
	sprite.material.shader = _avatar_shader
	var ratio = $FightingZone.scale.x / server_width
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

func _on_entity_moved(unit_id: int, x: int, y: int):
	print("Entity %d moved to (%d, %d)" % [unit_id, x, y])
	var unit = _units.get(unit_id)
	if unit == null:
		print("Unknown entity")
		return
	unit.position_start = unit.entity.position
	unit.position_target = _server_pos_to_client_pos(Vector2(x, y))
	unit.moving_time = 0

func _on_entity_damaged(unit_id: int, attacker_id: int, new_size: int):
	print("Entity %d attacked by %d, new size %d" % [unit_id, attacker_id, new_size])
	var unit = _units.get(unit_id)
	if unit == null:
		print("Unknown entity")
		return
	var ratio = $FightingZone.scale.x / server_width
	unit.entity.scale = Vector2(float(new_size) / IMAGE_WIDTH * ratio, float(new_size) / IMAGE_HEIGHT * ratio)

func _on_entity_despawned(unit_id: int):
	print("Entity %d despawned" % [unit_id])
	var unit = _units.get(unit_id)
	if unit == null:
		print("Unknown entity")
		return
	unit.entity.queue_free()
	_units.erase(unit_id)
