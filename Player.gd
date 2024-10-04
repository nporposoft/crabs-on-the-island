class_name Player

extends Node2D

var _character: CharacterBody2D

func _ready() -> void:
	_character = $Crab

func _process(delta: float) -> void:
	var input: Vector2
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	_character.move(input.normalized())
