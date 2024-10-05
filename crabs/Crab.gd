class_name Crab

extends RigidBody2D

@export var move_battery_usage: float = 0.1
@export var dodge_battery_usage: float = 0.5
@export var harvest_battery_usage: float = 0.1
@export var dodge_cooldown_seconds: float = 1.67
@export var dodge_duration: float = 0.5
@export var dodge_speed_multiplier: float = 1.0

const movementThreshold: float = 5.0

signal carried_iron_changed
signal carried_cobalt_changed
signal carried_silicon_changed
signal carried_water_changed
signal battery_charge_changed


var _direction: Util.Directions = Util.Directions.DOWN

enum States { 
	RUNNING = 0,
	DODGING = 1,
	DODGE_COOLDOWN = 2,
	ATTACKING = 3,
	REPRODUCING = 4,
	OUT_OF_BATTERY = 5
}
var _state: int

var _current_animation: String
var _current_flip_h: bool

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


func init(body_resources: Dictionary, stats: Dictionary) -> void:
	_body_resources = body_resources
	_stats = stats


func move(movementDirection: Vector2) -> void:
	if _has_any_state([States.REPRODUCING, States.OUT_OF_BATTERY, States.DODGING]): return
	if movementDirection.length() == 0: return
	
	_set_state(States.RUNNING)
	_direction = Util.get_direction_from_vector(movementDirection)
	apply_central_force(movementDirection.normalized() * _stats.move_speed)


func dodge() -> void:
	if _has_any_state([States.DODGING, States.DODGE_COOLDOWN, States.OUT_OF_BATTERY, States.REPRODUCING]): return

	_set_state(States.DODGING)
	_set_state(States.DODGE_COOLDOWN)
	var direction: Vector2 = Util.get_vector_from_direction(_direction)
	apply_central_impulse(direction * _stats.move_speed * dodge_speed_multiplier)
	_modify_battery_energy(-dodge_battery_usage)
	_one_shot_timer(dodge_duration, func() -> void:
		_unset_state(States.DODGING)
	)
	_one_shot_timer(dodge_cooldown_seconds, func() -> void:
		_unset_state(States.DODGE_COOLDOWN)	
	)

func harvest() -> void:
	if _has_state(States.OUT_OF_BATTERY): return
	
	var closestDist = 100.0
	var pickups_in_reach = $reach_area.get_overlapping_bodies()
	for item: RigidBody2D in pickups_in_reach:
		var resource = item as Morsel
		if item == null: continue
		
		pass


func get_mutations(num_options: int = 1) -> Array:
	var mutations: Array
	for _i in num_options:
		mutations.push_back(MutationEngine.get_mutation_options(_stats))
	return mutations


func _process(delta: float) -> void:
	_update_movement_state()
	_harvest_sunlight(delta)
	_deplete_battery_from_movement(delta)
	_update_animation_from_state()


func _harvest_sunlight(delta: float) -> void:
	var time: float = WorldClock.time
	if time > 0.25 && time < 0.75:
		var gained_energy: float = _stats.solar_efficiency * delta
		_modify_battery_energy(gained_energy)


func _deplete_battery_from_movement(delta: float) -> void:
	if !_has_state(States.RUNNING): return
	
	var lost_energy: float = move_battery_usage * delta
	_modify_battery_energy(-lost_energy)


func _modify_battery_energy(value: float) -> void:
	_carried_resources.battery_energy = clampf(_carried_resources.battery_energy + value, 0, _stats.battery_capacity)
	if _has_state(States.OUT_OF_BATTERY) && _carried_resources.battery_energy > 0:
		_unset_state(States.OUT_OF_BATTERY)
	elif _carried_resources.battery_energy == 0:
		_set_state(States.OUT_OF_BATTERY)
	battery_charge_changed.emit()


func _update_movement_state() -> void:
	if _has_any_state([States.OUT_OF_BATTERY, States.DODGING]): return
	
	if linear_velocity.length() < movementThreshold:
		_unset_state(States.RUNNING)


func _update_animation_from_state() -> void:
	var animation: String
	var flip_h: bool
	
	if _direction in Util.LeftDirections: flip_h = true
	
	if _has_state(States.OUT_OF_BATTERY):
		animation = "sleep"
	elif _has_state(States.DODGING):
		animation = "dodge"
	elif _has_state(States.RUNNING):
		animation = "move"
	else:
		animation = "idle"
	
	if animation != _current_animation || flip_h != _current_flip_h:
		_current_animation = animation
		_current_flip_h = flip_h
		$AnimatedSprite2D.play(_current_animation)
		$AnimatedSprite2D.flip_h = _current_flip_h


func _one_shot_timer(duration: float, callback: Callable) -> void:
	var timer: Timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func() -> void:
		callback.call()
		remove_child(timer)
		timer.queue_free()	
	)
	add_child(timer)
	timer.start()


func _has_state(state: States) -> bool:
	var mask: int = 1 << state
	return _state & mask


func _has_any_state(states: Array[States]) -> bool:
	for state: States in states:
		if _has_state(state): return true
	return false


func _set_state(state: States) -> void:
	var mask: int = 1 << state
	_state = _state | mask


func _unset_state(state: States) -> void:
	var mask: int = 1 << state
	_state = _state & ~mask
