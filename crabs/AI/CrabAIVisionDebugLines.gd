extends Node

var _ai: CrabAI
var _lines: Array


func _ready() -> void:
	_ai = get_parent()


func _process(_delta: float) -> void:
	if !DebugMode.enabled:
		_clear_lines()
		return
	
	if _lines.is_empty():
		for direction: Vector2 in _ai._vision_ray_directions:
			_draw_line(direction)


func _draw_line(direction: Vector2) -> void:
	var line2d: Line2D = Line2D.new()
	line2d.width = 1.0
	line2d.add_point(Vector2.ZERO)
	line2d.add_point(direction * _ai._vision_distance)
	_lines.push_back(line2d)
	_ai._crab.add_child(line2d)


func _clear_lines() -> void:
	for line: Line2D in _lines:
		line.queue_free()
	_lines.clear()
