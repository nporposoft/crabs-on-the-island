class_name CrabAI

extends Node


signal on_target(target: Vector2)

@onready var _crab: Crab = get_parent()
var _state: States
var enabled: bool = true

var _attack_target: Crab
var _visible_resources_cache: ResourceCollection
var _resources_in_reach_cache: ResourceCollection

@export var dash_chance: float = 0.1
@export var dash_attack_chance: float = 0.5

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
	
	_cache_resources()
	
	if _harvest_routine(delta): return
	if _continue_attack_routine(delta): return
	if _harvest_crab_routine(delta): return
	
	on_target.emit(Vector2.ZERO)
	
	_wander_routine()


func _sleep_routine() -> bool:
	if _out_of_battery():
		_sleep()
		return true
	return false


func _continue_attack_routine(delta: float) -> bool:
	if _stop_attacking():
		_attack_target = null
		_crab.stop_harvest()
		return false
	
	_attack_crab(delta, _attack_target)
	return true


func _stop_attacking() -> bool:
	if !is_instance_valid(_attack_target): return true
	if !_want_to_attack_crab(_attack_target): return true
	return _visible_resources().crabs().has(_attack_target)

func _reproduce_routine(delta: float) -> bool:
	if _crab.has_reproduction_resources():
		if _crab.can_reproduce(): _reproduce(delta)
		else: _state = States.CHARGING_BATTERY
		return true
	return false


func _harvest_routine(delta: float) -> bool:
	if _harvest_sand_routine(delta) || _harvest_water_routine(delta) || _harvest_metal_routine(delta):
		_state = States.HARVESTING
		return true
	_crab.stop_harvest()
	return false


func _harvest_sand_routine(delta: float) -> bool:
	if !_want_silicon(): return false
	
	var sand: Sand = _visible_resources().nearest_sand()
	if !sand: return false

	if _resources_in_reach().sand().has(sand):
		_crab.harvest_sand(delta)
	else:
		_move_toward_point(sand.position)
	return true


func _harvest_water_routine(delta: float) -> bool:
	if !_want_water(): return false

	var water: Water = _visible_resources().nearest_water()
	if !water: return false

	if _resources_in_reach().water().has(water):
		_crab.harvest_water(delta)
	else:
		_move_toward_point(water.position)
	return true


func _harvest_metal_routine(delta: float) -> bool:
	if !_want_metal(): return false

	var morsel: Morsel = _visible_resources().nearest_morsel()
	if !morsel: return false

	if _resources_in_reach().morsels().has(morsel):
		_crab.harvest_morsel(delta, morsel)
	else:
		_move_toward_point(morsel.position)
	return true


func _harvest_crab_routine(delta: float) -> bool:
	if !_can_attack(): return false
	
	if is_instance_valid(_attack_target) && !_attack_target.is_dead():
		_attack_crab(delta, _attack_target)
	
	for crab: Crab in _visible_resources().crabs():
		if !_want_to_attack_crab(crab): continue
		
		_attack_crab(delta, crab)
		return true
	
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
	on_target.emit(point)
	var direction: Vector2 = point - _crab.position
	_move(direction)


func _move(direction: Vector2) -> void:
	_crab.move(direction)
	if randf() == dash_chance:
		_crab.dash()


func _can_attack() -> bool:
	return _crab._contains_cobalt


func _want_to_attack_crab(crab: Crab) -> bool:
	return crab.will_drop_metal() && _want_metal()


func _attack_crab(delta: float, crab: Crab) -> void:
	_state = States.ATTACKING
	if _resources_in_reach().crabs().has(crab):
		_crab.attackCrab(crab, delta)
	else:
		_move_toward_point(crab.position)
		if randf() == dash_attack_chance:
			_crab.dash()


func _want_metal() -> bool:
	return _crab._carried_resources.metal < _crab.metalTarget


func _want_water() -> bool:
	return _crab._carried_resources.water < _crab.waterTarget


func _want_silicon() -> bool:
	return _crab._carried_resources.silicon < _crab.siliconTarget


func _visible_resources() -> ResourceCollection:
	return _visible_resources_cache


func _resources_in_reach() -> ResourceCollection:
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
