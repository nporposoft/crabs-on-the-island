class_name Player

extends Node


func _process(delta: float) -> void:
	_process_movement()
	_process_dodge()
	_process_harvest(delta)
	_update_camera_position()


func _process_dodge() -> void:
	if Input.is_action_just_pressed("dodge"):
		$Crab.dodge()


func _process_movement() -> void:
	var moveInput: Vector2
	moveInput.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	moveInput.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	$Crab.move(moveInput)


func _process_harvest(delta) -> void:
	if Input.is_action_pressed("harvest"):
		$Crab.harvest(delta)


func _update_camera_position() -> void:
	$Camera2D.position = $Crab.position
	$Camera2D.transform = $Crab.transform
