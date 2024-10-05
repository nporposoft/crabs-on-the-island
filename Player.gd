class_name Player

extends Node

var _character: CharacterBody2D

func _ready() -> void:
	_character = $Crab

func _process(delta: float) -> void:
	var moveDir = Vector2(0.0, 0.0)
	if Input.is_action_pressed("move_up"):
		moveDir.y = -1.0
	if Input.is_action_pressed("move_down"):
		moveDir.y = 1.0
	if Input.is_action_pressed("move_left"):
		moveDir.x = -1.0
	if Input.is_action_pressed("move_right"):
		moveDir.x = 1.0
	
	var moveActual = moveDir.normalized()
	
	#var input: Vector2
	#input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	#input.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	#_character.move(input.normalized())

	$Camera2D.position = _character.position
