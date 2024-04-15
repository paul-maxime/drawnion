extends ProgressBar

@export var levels: Array[int] = [1600, 3200, 4800, 6400]
var _step_entities = {}
var _targeted_level = levels[0]

func _ready():
	var step_entity = preload ("res://scenes/ManaBarStep.tscn")
	for level in levels:
		_step_entities[level] = step_entity.instantiate()
		_step_entities[level].position.x = 2
		add_child(_step_entities[level])
	%Network.player_mana.connect(_on_player_mana)

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		var pos = get_local_mouse_position()
		if pos.x < 0||pos.y < 0||pos.x > size.x||pos.y > size.y:
			return
		var closest_distance = 0
		var closest_level = null
		for level in _step_entities:
			var entity = _step_entities[level]
			var distance = abs(pos.y - entity.position.y)
			if closest_level == null or distance < closest_distance:
				closest_level = level
				closest_distance = distance
		_targeted_level = closest_level
		get_node("/root/Arena").summon_size = _targeted_level / 100
		$ManaCursor.position.y = _step_entities[_targeted_level].position.y + _step_entities[_targeted_level].size.y / 2 - $ManaCursor.size.y / 2

var mana_start = 0
var mana_target = 0
var interpolation_time = 0
func _on_player_mana(mana: int, max_mana: int):
	_update_max_value(max_mana)
	mana_start = value
	mana_target = log(mana) * log(mana)
	interpolation_time = 0

func _update_max_value(max_mana: int):
	if max_mana == 0:
		return
	var new_max_value = log(max_mana) * log(max_mana)
	if max_mana != new_max_value:
		for level in _step_entities:
			var entity = _step_entities[level]
			var mana_ratio = float(log(level) * log(level)) / new_max_value
			entity.position.y = size.y - size.y * mana_ratio - entity.size.y / 2
			if _targeted_level == level:
				$ManaCursor.position.y = size.y - size.y * mana_ratio - $ManaCursor.size.y / 2
	max_value = new_max_value

func _process(delta):
	if value != mana_target:
		interpolation_time += delta * 4
		interpolation_time = min(1, interpolation_time)
		value = mana_start * (1 - interpolation_time) + mana_target * interpolation_time
