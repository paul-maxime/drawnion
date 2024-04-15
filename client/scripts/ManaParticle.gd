extends Node2D

var _destination: Vector2
var _velocity: Vector2

func set_destination(destination: Vector2):
	_destination = destination
	_velocity = Vector2(randi_range(-200, 100), randi_range(-100, 50))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var distance = _destination.distance_to(position)
	var target_velocity = (_destination - position).normalized() * max(distance, 500)
	var force = (target_velocity - _velocity).normalized() * 500
	_velocity += force * delta
	position += _velocity * delta;
	if position.distance_to(_destination) < 10.0 || position.x > _destination.x:
		queue_free()
