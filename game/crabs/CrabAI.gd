class_name CrabAI

extends Node


@onready var _crab: Crab = get_parent()
var _state: State = State.new()
var enabled: bool = true

var _wander_direction: Vector2
var _wander_timer: Timer

var _attack_target: Crab

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
	if _continue_attack_routine(delta): return
	if _reproduce_routine(delta): return
	if _harvest_routine(delta): return
	if _crab_harvest_routine(delta): return
	_wander_routine()


func _sleep_routine() -> bool:
	if _out_of_battery():
		_sleep()
		return true
	_state.remove(States.SLEEPING)
	return false


func _continue_attack_routine(delta: float) -> bool:
	if _attack_target == null: return false
	
	_attack_crab(delta, _attack_target)
	return true


func _reproduce_routine(delta: float) -> bool:
	if _crab.has_reproduction_resources():
		_clear_states()

		if _crab.can_reproduce(): _reproduce(delta)
		else: _state.add(States.CHARGING_BATTERY)
		return true
	return false


func _harvest_routine(delta: float) -> bool:
	#var visible_resources: Array = _crab.visible_resources()
	#for resource: Harvestable in visible_resources:
		#if !_want_resource(resource): continue
		#
		#_clear_states()
		#
		#if _can_reach_resource(resource): 
			#_harvest_resource(delta, resource)
		#else:
			#_clear_states()
			#_move_toward_resource(resource)
		#return true
	#
	#return false
	return false


func _crab_harvest_routine(delta: float) -> bool:
	if _crab.has_reproduction_resources(): return false
	if !_crab._contains_cobalt: return false
	
	var nearby_crabs: Array = _get_nearby_crabs()
	for crab in nearby_crabs:
		if _want_to_attack_crab(crab):
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


#func _move_toward_resource(resource: Harvestable) -> void:
	#_sm.set_state(States.MOVING_TO_RESOURCE)
	#_move_toward_point(resource.position)
#
#
func _move_toward_point(point: Vector2) -> void:
	var direction: Vector2 = point - _crab.position
	_crab.move(direction)


#func _harvest_resource(delta: float, resource: Harvestable) -> void:
	#_sm.set_state(States.HARVESTING)
	#match resource.type:
		#Harvestable.HarvestableType.SAND:
			#return # TODO
		#Harvestable.HarvestableType.WATER:
			#return # TODO
		#Harvestable.HarvestableType.MORSEL:
			#_crab.harvest_morsel(delta, resource.morsel)
		#_:
			#return


func _harvest_morsel(delta: float, morsel: Morsel) -> void:
	_state.add(States.HARVESTING)
	_crab.harvest_morsel(delta, morsel)


func _want_to_attack_crab(crab: Crab) -> bool:
	return crab.will_drop_metal() && _want_metal()


func _get_nearby_crabs() -> Array:
	return (
		_crab.crabs_within_reach()
		.filter(func(crab: Crab) -> bool: return crab != _crab)
	)


func _can_reach_crab(crab: Crab) -> bool:
	return _crab.crabs_within_reach().has(crab)


func _attack_crab(delta: float, crab: Crab) -> void:
	_state.add(States.ATTACKING)
	if _can_reach_crab(crab):
		_crab.attackCrab(crab, delta)
	else:
		_move_toward_point(crab.position)


func _stop_harvesting() -> void:
	_crab.stop_harvest()
	_state.remove(States.HARVESTING)

#
#func _want_resource(resource: Harvestable) -> bool:
	#match resource.type:
		#Harvestable.HarvestableType.SAND:
			#return _want_silicon()
		#Harvestable.HarvestableType.WATER:
			#return _want_water()
		#Harvestable.HarvestableType.MORSEL:
			#return _want_morsel(resource.morsel)
		#_:
			#return false
#
#
#func _can_reach_resource(resource: Harvestable) -> bool:
	#match resource.type:
		#Harvestable.HarvestableType.SAND:
			#return false # TODO
		#Harvestable.HarvestableType.WATER:
			#return false # TODO
		#Harvestable.HarvestableType.MORSEL:
			#return _crab.can_reach_morsel(resource.morsel)
		#_:
			#return false


func _want_morsel(_morsel: Morsel) -> bool:
	return _want_metal()


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
