class_name Camera

extends Camera2D

@export var _pan_strength: float = 0.5
@export var _zoom_strength: float = 0.5
@export var _max_zoom: int = 5
@export var _min_zoom: int = 1
@export var _current_zoom: int = _max_zoom

var _target: Node2D


func set_target(target: Node2D) -> void:
	_target = target
	position = target.position


func _process(_delta: float) -> void:
	_update_zoom_level()
	_update_position()


func _update_zoom_level() -> void:
	if Input.is_action_just_pressed("zoom_in"):
		_current_zoom = min(_current_zoom + 1, _max_zoom)
	elif Input.is_action_just_pressed("zoom_out"):
		_current_zoom = max(_current_zoom - 1, _min_zoom)
	var desired_zoom: float = _current_zoom / 5.0
	zoom = zoom.lerp(Vector2(desired_zoom, desired_zoom), _zoom_strength)


func _update_position() -> void:
	if is_instance_valid(_target):
		position = position.lerp(_target.position, _pan_strength)
