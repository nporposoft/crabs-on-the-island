class_name CrabAI

extends Node


signal on_target(target: Vector2)

@onready var _crab: Crab = get_parent()
var _state: States
var enabled: bool = true

var _visible_resources_cache: ResourceCollection
var _resources_in_reach_cache: ResourceCollection

@export var vision_interval: float = 0.3
@export var vision_interval_jitter: float = 0.1
var _vision_timer: Timer

@export var min_wander_time: float = 1.0
@export var max_wander_time: float = 3.0
var _wander_direction: Vector2
var _wander_timer: Timer

enum States {
	IDLING,
	WANDERING,
	MOVING_TO_RESOURCE,
	HARVESTING,
	REPRODUCING,
	CHARGING_BATTERY,
	SLEEPING,
	ATTACKING
}


func _ready() -> void:
	_create_wander_timer()
	_create_vision_timer()


func _process(delta: float) -> void:
	if !enabled: return
	if _sleep_routine(): return
	if _reproduce_routine(delta): return
	if _harvest_routine(delta): return
	_wander_routine()


func _sleep_routine() -> bool:
	if _out_of_battery():
		_sleep()
		return true
	return false


func _reproduce_routine(delta: float) -> bool:
	if _crab.has_reproduction_resources():
		_crab.stop_harvest() # TODO: would be nice if the Crab state machine handled this
		on_target.emit(Vector2.ZERO)
		if _crab.can_reproduce(): _reproduce(delta)
		else: _state = States.CHARGING_BATTERY
		return true
	return false


func _harvest_routine(delta: float) -> bool:
	var resources_in_reach: Array = _resources_in_reach().all()
	var visible_resources: Array = _visible_resources().by_distance(_crab.position)
	for resource in visible_resources:
		# since we are caching resources, sometimes things die or disappear between vision checks
		if not is_instance_valid(resource): continue

		if _crab.want_resource(resource):
			if resources_in_reach.has(resource):
				return _harvest_resource(resource, delta)
			else:
				_move_toward_point(resource.position)
				return true

	_crab.stop_harvest() # TODO: would be nice if the Crab state machine handled this
	on_target.emit(Vector2.ZERO)
	return false


func _harvest_resource(resource: Node2D, delta: float) -> bool:
	if resource is Crab:
		return _crab.attack(resource, delta)
	if resource is Sand:
		return _crab.harvest_sand(delta)
	if resource is Water:
		return _crab.harvest_water(delta)
	if resource is Morsel:
		return _crab.harvest_morsel(delta, resource)
	return false


func _wander_routine() -> void:
	if _state == States.WANDERING:
		if _time_to_idle(): _start_idling()
		else: _keep_wandering()
	else:
		if _time_to_wander(): _start_wandering()


func _sleep() -> void:
	_state = States.SLEEPING


func _out_of_battery() -> bool:
	return _crab.state.has(Crab.States.OUT_OF_BATTERY)


func _start_wandering() -> void:
	_wander_direction = Util.random_direction()
	_state = States.WANDERING
	_start_wander_timer()


func _start_idling() -> void:
	_state = States.IDLING
	_crab.move(Vector2.ZERO) # TODO: would be nice if the Crab state machine handled this
	_start_idle_timer()


func _reproduce(delta: float) -> void:
	_state = States.REPRODUCING
	_crab.auto_reproduce(delta)


func _time_to_idle() -> bool:
	return _wander_timer.is_stopped()


func _time_to_wander() -> bool:
	return _wander_timer.is_stopped()


func _start_wander_timer() -> void:
	_wander_timer.wait_time = randf_range(min_wander_time, max_wander_time)
	_wander_timer.start()


func _start_idle_timer() -> void:
	_start_wander_timer()


func _keep_wandering() -> void:
	_move(_wander_direction)


func _move_toward_point(point: Vector2) -> void:
	# TODO: this signal is firing a lot -- it only gets used to draw the debug lines
	# maybe should only emit when the point changes
	on_target.emit(point)

	# TODO: sometimes crabs get hung up on other crabs and can't reach their target
	# we should add some "stuck detection" logic and try to move away from the obstacle for a second
	# to jostle free
	var direction: Vector2 = point - _crab.position
	_move(direction)


func _move(direction: Vector2) -> void:
	_crab.move(direction)


func _visible_resources() -> ResourceCollection:
	if _vision_timer.is_stopped(): _cache_resources()
	return _visible_resources_cache


func _resources_in_reach() -> ResourceCollection:
	if _vision_timer.is_stopped(): _cache_resources()
	return _resources_in_reach_cache


func _cache_resources() -> void:
	if !_vision_timer.is_stopped(): return
	
	_visible_resources_cache = _crab.vision.get_resources()
	_resources_in_reach_cache = _crab.reach.get_resources()
	_vision_timer.start(randf_range(vision_interval - vision_interval_jitter, vision_interval + vision_interval_jitter))


func _create_wander_timer() -> void:
	_wander_timer = Timer.new()
	_wander_timer.one_shot = true
	add_child(_wander_timer)


func _create_vision_timer() -> void:
	_vision_timer = Timer.new()
	_vision_timer.one_shot = true
	add_child(_vision_timer)
