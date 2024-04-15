extends Button

@export var button_off_icon: CompressedTexture2D
@export var button_on_1_icon: CompressedTexture2D
@export var button_on_2_icon: CompressedTexture2D
@export var button_on_3_icon: CompressedTexture2D

# Called when the node enters the scene tree for the first time.
func _ready():
	_on_toggled(button_pressed)
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	connect("toggled", _on_toggled)

func _on_mouse_entered():
	if !button_pressed:
		icon = button_on_2_icon

func _on_mouse_exited():
	if !button_pressed:
		icon = button_on_1_icon

func _on_toggled(state: bool):
	if state:
		process_mode = Node.PROCESS_MODE_DISABLED
		icon = button_on_3_icon
	else:
		process_mode = Node.PROCESS_MODE_INHERIT
		icon = button_on_1_icon
