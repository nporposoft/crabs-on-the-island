class_name Crab

extends CharacterBody2D

@export var _speed: float

var body_resources: Dictionary
var carried_resources: Dictionary


func _process(_delta: float) -> void:
	move_and_slide()


func move(new_velocity: Vector2) -> void:
	velocity = new_velocity * _speed
