extends Node

var socket = WebSocketPeer.new()
var server_url = "ws://172.17.171.73:8080";

signal game_joined(player_id: int)

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
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.

func _on_message_received(message):
	match message.type:
		"hello":
			game_joined.emit(message.playerId)
		_:
			print("Unknown message: ", message)

func _on_hello(message):
	print("Joined the game, player id: %d" % [message.playerId])
