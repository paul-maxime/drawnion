extends Node2D

var _size: int = 16
var _is_dead: bool = false

@export var circle_color = Color(0, 0, 1, 0.8)

func set_entity_size(size: int):
	_size = size
	queue_redraw()

func _draw():
	if _is_dead:
		return
	draw_circle(Vector2.ZERO, _size / 2.0, circle_color)

func explode_and_die():
	_is_dead = true
	queue_redraw()
	$Sprite.queue_free()
	$Particles.emitting = true
	$Particles.modulate = circle_color
	$Particles.finished.connect(queue_free)
