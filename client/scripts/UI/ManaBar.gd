extends ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready():
	%Network.player_mana.connect(_on_player_mana)

var mana_start = 0
var mana_target = 0
var interpolation_time = 0
func _on_player_mana(mana: int, max_mana: int):
	max_value = max_mana
	mana_start = value
	mana_target = mana
	interpolation_time = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if value != mana_target:
		interpolation_time += delta * 2
		interpolation_time = min(1, interpolation_time)
		value = mana_start * (1 - interpolation_time) + mana_target * interpolation_time
