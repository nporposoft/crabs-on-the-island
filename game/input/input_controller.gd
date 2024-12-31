class_name InputController

extends Node

var _manager: InputManager


# Stub to be overridden by subclasses
func process(_delta: float) -> void:
	pass


func set_manager(manager: Node) -> void:
	_manager = manager