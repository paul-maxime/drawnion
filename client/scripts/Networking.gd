extends Node

var socket = WebSocketPeer.new()
var server_url = "wss://paulmaxime.fr/ws/drawnion/";

signal game_joined(player_id: int, map_width: int, map_height: int)
signal player_avatar_received(player_id: int, pixels: Array)
signal entity_summoned(entity_id: int, owner_id: int, x: int, y: int, size: int, element: int)
signal entity_moved(entity_id: int, x: int, y: int)
signal entity_damaged(entity_id: int, attacker_id: int, new_size: int)
signal entity_despawned(entity_id: int)
signal network_closed()

func _ready():
	print("Connecting to " + server_url)
	socket.connect_to_url(server_url)

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var raw = socket.get_packet()
			var message = JSON.parse_string(raw.get_string_from_utf8())
			_on_message_received(message)
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != - 1])
		network_closed.emit()
		set_process(false) # Stop processing.

func _on_message_received(message):
	match message.type:
		"hello":
			game_joined.emit(message.playerId, message.mapWidth, message.mapHeight)
		"avatar":
			player_avatar_received.emit(message.playerId, message.pixels)
		"summon":
			entity_summoned.emit(message.entityId, message.ownerId, message.x, message.y, message.size, message.element)
		"move":
			entity_moved.emit(message.entityId, message.x, message.y)
		"damage":
			entity_damaged.emit(message.entityId, message.attackerId, message.newSize)
		"despawn":
			entity_despawned.emit(message.entityId)
		_:
			print("Unknown message: ", message)

func sendAvatar(pixels: Array[int]):
	_send({
		"type": "avatar",
		"pixels": pixels
	});

func sendSummon(x: int, y: int, size: int, element: int):
	_send({
		"type": "summon",
		"x": x,
		"y": y,
		"size": size,
		"element": element,
	});

func _send(message):
	socket.send_text(JSON.stringify(message))
