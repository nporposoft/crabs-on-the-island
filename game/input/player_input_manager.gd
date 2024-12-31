class_name PlayerInputManager

extends Node

var _controllers: Array[PlayerInputController] = []


func _process(delta: float) -> void:
	var current_controller: PlayerInputController = _controllers.back()
	if current_controller != null:
		current_controller.process(delta)


func set_controller(controller: PlayerInputController) -> void:
	_controllers.push_back(controller)
	controller.set_manager(self)


func remove_controller() -> void:
	_controllers.pop_back()


func replace_controller(controller: PlayerInputController) -> void:
	_controllers.pop_back()
	set_controller(controller)