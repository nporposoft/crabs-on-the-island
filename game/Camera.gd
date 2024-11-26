class_name Camera

extends Camera2D

@export var _pan_strength: float = 0.5
@export var _zoom_strength: float = 0.5

const max_zoom: int = 5
const min_zoom: int = 1
var current_zoom: int = max_zoom

var target: Node2D


func init(target: Node2D) -> void:
	self.target = target
	position = target.position


func _process(_delta: float) -> void:
	_update_zoom_level()
	_update_position()


func _update_zoom_level() -> void:
	if Input.is_action_just_pressed("zoom_in"):
		current_zoom = min(current_zoom + 1, max_zoom)
	elif Input.is_action_just_pressed("zoom_out"):
		current_zoom = max(current_zoom - 1, min_zoom)
	var desired_zoom: float = current_zoom / 5.0
	zoom = zoom.lerp(Vector2(desired_zoom, desired_zoom), _zoom_strength)


func _update_position() -> void:
	if is_instance_valid(target):
		position = position.lerp(target.position, _pan_strength)
