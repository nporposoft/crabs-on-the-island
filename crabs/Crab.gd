class_name Crab

extends CharacterBody2D

var _body_resources: Dictionary
var _carried_resources: Dictionary
var _stats: Dictionary = {
	"size": 1,
	"hit_points": 10,
	"strength": 10,
	"speed": 100,
	"solar_efficiency": 10,
	"battery_capacity": 10,
	"harvest_speed": 10
}

# TODO: remove and use _stats instead
@export var _move_speed: int = 100

func init(body_resources: Dictionary, stats: Dictionary) -> void:
	_body_resources = body_resources
	_stats = stats


func _process(_delta: float) -> void:
	move_and_slide()


func move(new_velocity: Vector2) -> void:
	velocity = new_velocity * _move_speed
