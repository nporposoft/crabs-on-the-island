class_name Clock

extends Node

var time: float = 0.3
@export var _time_scale: float = 0.01


func _process(delta: float) -> void:
	time = fmod(time + (delta * _time_scale), 1.0)
