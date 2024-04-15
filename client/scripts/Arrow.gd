extends Node2D

var _map_size: Vector2i
var _expected_position: Vector2 = Vector2.ZERO
var _expected_rotation: float = 0

func set_map_size(width: int, height: int):
	_map_size = Vector2i(width, height)

func update_position(client_pos: Vector2, server_pos: Vector2):
	var new_position = client_pos
	var new_rotation = 0
	if server_pos.x == 0:
		new_rotation = 0
		new_position += Vector2(16, 0)
	elif server_pos.y == 0:
		new_rotation = PI / 2
		new_position += Vector2(0, 16)
	elif server_pos.x == _map_size.x - 1:
		new_rotation = 2 * PI / 2
		new_position += Vector2(-16, 0)
	elif server_pos.y == _map_size.y - 1:
		new_rotation = 3 * PI / 2
		new_position += Vector2(0, -16)
	_expected_position = new_position
	_expected_rotation = new_rotation

func _process(delta):
	position = position.lerp(_expected_position, delta * 20.0)
	rotation = lerp_angle(rotation, _expected_rotation, delta * 10.0)
