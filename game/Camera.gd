class_name Camera

extends Camera2D

@export var _pan_strength: float = 0.5

var _target: Node2D


func init_target(target: Node2D) -> void:
	set_target(target)
	position = target.position


func set_target(target: Node2D) -> void:
	_target = target


func _process(_delta: float) -> void:
	_update_position()


func _update_position() -> void:
	if is_instance_valid(_target):
		position = position.lerp(_target.position, _pan_strength)
