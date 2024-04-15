extends VBoxContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	$GrassButton.connect("toggled", _on_button_pressed.bind(1))
	$FireButton.connect("toggled", _on_button_pressed.bind(2))
	$WaterButton.connect("toggled", _on_button_pressed.bind(3))
	var element = get_node("/root/Arena").selected_element
	if element == 1:
		$GrassButton.button_pressed = true
	elif element == 2:
		$FireButton.button_pressed = true
	elif element == 3:
		$WaterButton.button_pressed = true

func _on_button_pressed(_state: bool, element: int):
	get_node("/root/Arena").selected_element = element
	if element != 1:
		$GrassButton.set_block_signals(true)
		$GrassButton.button_pressed = false
		$GrassButton.process_mode = Node.PROCESS_MODE_INHERIT
		$GrassButton.set_block_signals(false)
	if element != 2:
		$FireButton.set_block_signals(true)
		$FireButton.button_pressed = false
		$FireButton.process_mode = Node.PROCESS_MODE_INHERIT
		$FireButton.set_block_signals(false)
	if element != 3:
		$WaterButton.set_block_signals(true)
		$WaterButton.button_pressed = false
		$WaterButton.process_mode = Node.PROCESS_MODE_INHERIT
		$WaterButton.set_block_signals(false)
