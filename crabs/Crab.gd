class_name Crab

extends RigidBody2D

@export var move_battery_usage: float = 0.1
@export var dodge_battery_usage: float = 0.5
@export var harvest_battery_usage: float = 0.1
@export var dodge_cooldown_seconds: float = 1.67
@export var dodge_speed_multiplier: float = 1.5

const movementThreshold: float = 5.0


var _direction: Util.Directions = Util.Directions.DOWN

enum States { IDLE, RUNNING, DODGING, ATTACKING, REPRODUCING, OUT_OF_BATTERY }
var _state: States = States.IDLE

var _current_animation: String
var _current_flip_h: bool
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
	if _state in [States.REPRODUCING, States.OUT_OF_BATTERY]: return
	
	_state = States.RUNNING
	_direction = Util.get_direction_from_vector(movementDirection)
	apply_central_force(movementDirection.normalized() * _stats.move_speed)


func dodge() -> void:
	if !_state in [States.IDLE, States.RUNNING]: return

	_state = States.DODGING
	var direction: Vector2 = Util.get_vector_from_direction(_direction)
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
	if _state != States.RUNNING: return
	
	var lost_energy: float = move_battery_usage * delta
	_modify_battery_energy(-lost_energy)


func _modify_battery_energy(value: float) -> void:
	_carried_resources.battery_energy = clampf(_carried_resources.battery_energy + value, 0, _stats.battery_capacity)
	if _state == States.OUT_OF_BATTERY && _carried_resources.battery_energy > 0:
		_state = States.IDLE
	elif _carried_resources.battery_energy == 0:
		_state = States.OUT_OF_BATTERY


func _update_movement_state() -> void:
	if _state in [States.OUT_OF_BATTERY]: return
	
	if linear_velocity.length() < movementThreshold:
		_state = States.IDLE


func _update_animation_state() -> void:
	var animation: String
	var flip_h: bool
	
	match _state:
		States.IDLE:
			animation = "idle"
		States.RUNNING:
			animation = "move"
		States.OUT_OF_BATTERY:
			animation = "sleep"
		States.DODGING:
			animation = "dodge"
			if _direction in Util.LeftDirections: flip_h = true
	
	if animation != _current_animation || flip_h != _current_flip_h:
		_current_animation = animation
		_current_flip_h = flip_h
		$AnimatedSprite2D.play(_current_animation)
		$AnimatedSprite2D.flip_h = _current_flip_h
