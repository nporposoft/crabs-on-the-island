class_name Crab

extends CharacterBody2D

enum CrabStats {
	HP,
	STRENGTH,
	MOVE_SPEED,
	SOLAR_EFFICIENCY,
	HARVEST_SPEED,
	BATTERY_CAPACITY
}

var _body_resources: Dictionary
var _carried_resources: Dictionary
var _stats: Dictionary


func init(body_resources: Dictionary, stats: Dictionary) -> void:
	_body_resources = body_resources
	_stats = stats


func _process(_delta: float) -> void:
	move_and_slide()


func move(new_velocity: Vector2) -> void:
	velocity = new_velocity * _stats.move_speed
