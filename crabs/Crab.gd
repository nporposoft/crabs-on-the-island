class_name Crab

extends RigidBody2D

@export var move_battery_usage: float = 0.1
@export var dash_battery_usage: float = 0.5
@export var harvest_battery_usage: float = 0.1

enum Directions { UP, DOWN, LEFT, RIGHT }
var _direction: Directions = Directions.DOWN
enum States { IDLE, RUNNING, DODGING, ATTACKING, REPRODUCING, OUT_OF_BATTERY }
var _state: States = States.IDLE
var _current_animation: String

var _body_resources: Dictionary = {
	"iron": 0,
	"cobalt": 0,
	"silicon": 0,
	"water": 0,
}
var _carried_resources: Dictionary = {
	"iron": 0,
	"cobalt": 0,
	"silicon": 0,
	"water": 0,
	"battery_energy": 0.0,
}
var _stats: Dictionary = {
	"size": 1,
	"hit_points": 10,
	"strength": 10,
	"move_speed": 100.0,
	"solar_efficiency": 0.2,
	"battery_capacity": 10,
	"harvest_speed": 10
}


func init(body_resources: Dictionary, stats: Dictionary) -> void:
	_body_resources = body_resources
	_stats = stats


func _process(delta: float) -> void:
	_update_animation_state()
	_harvest_sunlight(delta)
	_deplete_battery_from_movement(delta)


func _harvest_sunlight(delta: float) -> void:
	var time: float = WorldClock.time
	if time > 0.25 && time < 0.75:
		var gained_energy: float = _stats.solar_efficiency * delta
		_set_battery_energy(_carried_resources.battery_energy + gained_energy)


func _deplete_battery_from_movement(delta: float) -> void:
	if !_is_moving():
		return
	
	var lost_energy: float = move_battery_usage * delta
	_set_battery_energy(_carried_resources.battery_energy - lost_energy)


func _set_battery_energy(value: float) -> void:
	_carried_resources.battery_energy = clampf(value, 0, _stats.battery_capacity)


func _update_animation_state() -> void:
	var animation: String
	if _is_moving():
		animation = "move"
	else:
		animation = "idle"
	
	if animation != _current_animation:
		_current_animation = animation
		$AnimatedSprite2D.play(_current_animation)


func _is_moving() -> bool:
	return linear_velocity.length() > 1
