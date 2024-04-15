extends Node2D

var _destination: Vector2
var _velocity: Vector2

func set_destination(destination: Vector2):
	_destination = destination
	_velocity = Vector2(randi_range(-100, 100), randi_range(-100, 100))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var before = (_destination - position).normalized()
	var target_velocity = before * 1000
	var force = (target_velocity - _velocity).normalized() * 5
	_velocity += force
	position += _velocity * delta;
	var after = (_destination - position).normalized()
	var angle = before.angle() - after.angle()
	if abs(angle) > 0.1 || position.distance_to(_destination) < 10.0:
		queue_free()
