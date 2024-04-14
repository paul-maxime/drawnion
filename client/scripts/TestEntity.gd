extends Node2D

var _size: int = 16

func _draw():
	draw_circle(Vector2.ZERO, _size / 2.0, Color(1, 0, 0, 0.5))
