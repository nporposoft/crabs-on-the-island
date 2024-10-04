class_name Player

extends Node2D

var _character: CharacterBody2D

func _ready() -> void:
	_character = $Crab

func _process(delta: float) -> void:
	var input: Vector2
	if Input.is_action_pressed("ui_down"):
		input.y = 1
	
	_character.move(input.normalized())
