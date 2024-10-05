class_name Clock

extends Node

var time: float = 0.3
var day_count: int
@export var _time_scale: float = 0.01


func _process(delta: float) -> void:
	time += delta * _time_scale
	if time > 1.0:
		day_count += 1
		time = fmod(time, 1.0)
