class_name CrabAI

extends Node


@onready var _crab: Crab = get_parent()
var _state: State = State.new()
var enabled: bool = true

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
	_state.remove(States.SLEEPING)
	return false


func _reproduce_routine(delta: float) -> bool:
	if _crab.has_reproduction_resources():
		_clear_states()

		if _crab.can_reproduce(): _reproduce(delta)
		else: _state.add(States.CHARGING_BATTERY)
		return true
	return false


func _harvest_routine(delta: float) -> bool:
	if _harvest_sand(delta): return true
	if _harvest_water(delta): return true
	if _harvest_metal(delta): return true
	if _harvest_crab(delta): return true
	return false


func _harvest_sand(delta: float) -> bool:
	if !_want_silicon(): return false
	
	var sand: SandCollider = _crab.vision.nearest_sand()
	if !sand: return false

	if _crab.reach.has_sand(sand):
		_clear_states()
		_state.add(States.HARVESTING)
		_crab.harvest_sand(delta)
	else:
		_move_toward_resource(sand)
	return true


func _harvest_water(delta: float) -> bool:
	if !_want_water(): return false

	var water: WaterCollider = _crab.vision.nearest_water()
	if !water: return false

	if _crab.reach.has_water(water):
		_clear_states()
		_state.add(States.HARVESTING)
		_crab.harvest_water(delta)
	else:
		_move_toward_resource(water)
	return true


func _harvest_metal(delta: float) -> bool:
	if !_want_metal(): return false

	var morsel: Morsel = _crab.vision.nearest_morsel()
	if !morsel: return false

	if _crab.reach.has_morsel(morsel):
		_clear_states()
		_state.add(States.HARVESTING)
		_crab.harvest_morsel(delta, morsel)
	else:
		_move_toward_resource(morsel)
	return true


func _harvest_crab(delta: float) -> bool:
	if !_can_attack(): return false
	
	for crab: Crab in _get_nearby_crabs():
		if !_want_to_attack_crab(crab): continue
		
		_attack_crab(delta, crab)
		return true
	
	return false


func _wander_routine() -> void:
	_stop_harvesting() # TODO: would be nice if the Crab state machine handled this
	if _state.has(States.WANDERING):
		if _time_to_idle(): _start_idling()
		else: _keep_wandering()
	else:
		if _time_to_wander(): _start_wandering()


func _sleep() -> void:
	_clear_states()
	_state.add(States.SLEEPING)


func _out_of_battery() -> bool:
	return _crab.state.has(Crab.States.OUT_OF_BATTERY)


func _clear_states() -> void:
	_state.clear()
	_stop_harvesting() # TODO: would be nice if the Crab state machine handled this


func _start_wandering() -> void:
	_wander_direction = Util.random_direction()
	_state.add(States.WANDERING)
	_state.remove(States.IDLING)
	_start_wander_timer()


func _start_idling() -> void:
	_state.remove(States.WANDERING)
	_state.add(States.IDLING)
	_crab.move(Vector2.ZERO) # TODO: would be nice if the Crab state machine handled this
	_start_idle_timer()


func _reproduce(delta: float) -> void:
	_state.add(States.REPRODUCING)
	_crab.auto_reproduce(delta)


func _time_to_idle() -> bool:
	return _wander_timer.is_stopped()


func _time_to_wander() -> bool:
	return _wander_timer.is_stopped()


func _start_wander_timer() -> void:
	_wander_timer.wait_time = randf_range(1.0, 3.0)
	_wander_timer.start()


func _start_idle_timer() -> void:
	_start_wander_timer()


func _keep_wandering() -> void:
	_crab.move(_wander_direction)


func _move_toward_resource(resource: Node2D) -> void:
	_clear_states()
	_state.add(States.MOVING_TO_RESOURCE)
	_move_toward_point(resource.position)


func _move_toward_point(point: Vector2) -> void:
	var direction: Vector2 = point - _crab.position
	_crab.move(direction)


func _harvest_morsel(delta: float, morsel: Morsel) -> void:
	_clear_states()
	_state.add(States.HARVESTING)
	_crab.harvest_morsel(delta, morsel)


func _can_attack() -> bool:
	return _crab._contains_cobalt


func _want_to_attack_crab(crab: Crab) -> bool:
	return crab.will_drop_metal() && _want_metal()


func _get_nearby_crabs() -> Array:
	return _crab.reach.crabs()


func _can_reach_crab(crab: Crab) -> bool:
	return _get_nearby_crabs().has(crab)


func _attack_crab(delta: float, crab: Crab) -> void:
	_clear_states()
	_state.add(States.ATTACKING)
	if _can_reach_crab(crab):
		_crab.attackCrab(crab, delta)
	else:
		_move_toward_point(crab.position)


func _stop_harvesting() -> void:
	_crab.stop_harvest()
	_state.remove(States.HARVESTING)


func _want_metal() -> bool:
	return _crab._carried_resources.metal < _crab.metalTarget


func _want_water() -> bool:
	return _crab._carried_resources.water < _crab.waterTarget


func _want_silicon() -> bool:
	return _crab._carried_resources.silicon < _crab.siliconTarget


func _create_wander_timer() -> void:
	_wander_timer = Timer.new()
	_wander_timer.one_shot = true
	add_child(_wander_timer)
