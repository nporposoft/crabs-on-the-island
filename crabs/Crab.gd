class_name Crab

extends RigidBody2D

@export var move_battery_usage: float = 0.1
@export var dodge_battery_usage: float = 0.5
@export var harvest_battery_usage: float = 0.1
@export var dodge_cooldown_seconds: float = 1.67
@export var dodge_speed_multiplier: float = 1.5

const movementThreshold: float = 0.5

enum Directions { UP, UP_LEFT, LEFT, DOWN_LEFT, DOWN, DOWN_RIGHT, RIGHT, UP_RIGHT }
var _direction: Directions = Directions.DOWN

enum States { IDLE, RUNNING, DODGING, ATTACKING, REPRODUCING, OUT_OF_BATTERY }
var _state: States = States.IDLE

var _current_animation: String
var _dodge_cooldown_timer: Timer

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
	"move_speed": 5000.0,
	"solar_efficiency": 0.2,
	"battery_capacity": 10,
	"harvest_speed": 10
}


func _ready() -> void:
	_dodge_cooldown_timer = Timer.new()
	_dodge_cooldown_timer.wait_time = dodge_cooldown_seconds
	_dodge_cooldown_timer.one_shot = true
	_dodge_cooldown_timer.timeout.connect(func() -> void:
		_state = States.IDLE
	)


func init(body_resources: Dictionary, stats: Dictionary) -> void:
	_body_resources = body_resources
	_stats = stats


func move(movementDirection: Vector2) -> void:
	_state = States.RUNNING
	_direction = _get_direction_from_vector(movementDirection)
	apply_central_force(movementDirection.normalized() * _stats.move_speed)


func dodge() -> void:
	if !_state in [States.IDLE, States.RUNNING]:
		return

	_state = States.DODGING
	var direction: Vector2 = _get_vector_from_direction(_direction)
	apply_central_impulse(direction * _stats.move_speed * dodge_speed_multiplier)
	_modify_battery_energy(-dodge_battery_usage)


func _process(delta: float) -> void:
	_update_movement_state()
	_update_animation_state()
	_harvest_sunlight(delta)
	_deplete_battery_from_movement(delta)


func _harvest_sunlight(delta: float) -> void:
	var time: float = WorldClock.time
	if time > 0.25 && time < 0.75:
		var gained_energy: float = _stats.solar_efficiency * delta
		_modify_battery_energy(gained_energy)


func _deplete_battery_from_movement(delta: float) -> void:
	if _state != States.RUNNING:
		return
	
	var lost_energy: float = move_battery_usage * delta
	_modify_battery_energy(-lost_energy)


func _modify_battery_energy(value: float) -> void:
	_carried_resources.battery_energy = clampf(_carried_resources.battery_energy + value, 0, _stats.battery_capacity)


func _update_movement_state() -> void:
	# TODO: do we need to gate against any states here?
	if linear_velocity.length() < movementThreshold:
		_state = States.IDLE


func _update_animation_state() -> void:
	var animation: String
	match _state:
		States.IDLE:
			animation = "idle"
		States.RUNNING:
			animation = "move"
	
	if animation != _current_animation:
		_current_animation = animation
		$AnimatedSprite2D.play(_current_animation)


func _get_direction_from_vector(vector: Vector2) -> Directions:
	if vector.x > movementThreshold && vector.y < -movementThreshold:
		return Directions.UP_RIGHT
	if vector.x > movementThreshold && vector.y > movementThreshold:
		return Directions.DOWN_RIGHT
	if vector.x < -movementThreshold && vector.y < -movementThreshold:
		return Directions.UP_LEFT
	if vector.x < -movementThreshold && vector.y > movementThreshold:
		return Directions.DOWN_LEFT
	if vector.y < -movementThreshold:
		return Directions.UP
	if vector.y > movementThreshold:
		return Directions.DOWN
	if vector.x < -movementThreshold:
		return Directions.LEFT
	# default to right
	return Directions.RIGHT


func _get_vector_from_direction(direction: Directions) -> Vector2:
	# default to right
	var vector: Vector2 = Vector2.RIGHT
	match direction:
		Directions.UP:
			vector = Vector2.UP
		Directions.UP_LEFT:
			vector = Vector2.UP + Vector2.LEFT
		Directions.LEFT:
			vector = Vector2.LEFT
		Directions.DOWN_LEFT:
			vector = Vector2.DOWN + Vector2.LEFT
		Directions.DOWN:
			vector = Vector2.DOWN
		Directions.DOWN_RIGHT:
			vector = Vector2.DOWN + Vector2.RIGHT
		Directions.UP_RIGHT:
			vector = Vector2.UP + Vector2.RIGHT
	return vector.normalized()
