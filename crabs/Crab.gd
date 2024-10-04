class_name Crab

extends CharacterBody2D

@export var _speed: float


func _process(_delta: float) -> void:
	move_and_slide()

func move(new_velocity: Vector2) -> void:
	velocity = new_velocity * _speed
