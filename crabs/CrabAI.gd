class_name CrabAI

extends Node


var _crab: Crab
var _island: IslandV1

@export var _vision_distance: float = 500.0

var _sm: MultiStateMachine = MultiStateMachine.new()
var _vision_ray_directions: Array = [
	Vector2.UP,
	Vector2(1,-1).normalized(),
	Vector2.RIGHT,
	Vector2(1, 1).normalized(),
	Vector2.DOWN,
	Vector2(-1, 1).normalized(),
	Vector2.LEFT,
	Vector2(-1, -1).normalized()
]

var _wander_direction: Vector2
var _wander_timer: Timer

enum States {
	IDLING,
	WANDERING,
	MOVING_TO_RESOURCE,
	HARVESTING
}


func _ready() -> void:
	_island = get_parent()
	_crab = $Crab
	_create_wander_timer()


func _physics_process(delta: float) -> void:
	var visibleMorsels: Array = _find_visible_morsels_by_distance()
	for morsel: Morsel in visibleMorsels:
		if !_want_morsel(morsel): continue
		
		_sm.unset_all_states()
		_crab.move(Vector2.ZERO) # gross
		
		if _crab.can_reach_morsel(morsel): _harvest_morsel(delta, morsel)
		else: _move_toward_morsel(morsel)
		return
	
	_stop_harvesting()
	
	if _sm.has_state(States.WANDERING):
		if _time_to_idle(): _start_idling()
		else: _keep_wandering()
	else:
		if _time_to_wander(): _start_wandering()


func _start_wandering() -> void:
	_wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_sm.set_state(States.WANDERING)
	_sm.unset_state(States.IDLING)
	_start_wander_timer()


func _start_idling() -> void:
	_sm.unset_state(States.WANDERING)
	_sm.set_state(States.IDLING)
	_crab.move(Vector2.ZERO) # gross
	_start_idle_timer()


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


func _move_toward_morsel(morsel: Morsel) -> void:
	_sm.set_state(States.MOVING_TO_RESOURCE)
	var direction: Vector2 = morsel.position - _crab.position
	_crab.move(direction)


func _harvest_morsel(delta: float, morsel: Morsel) -> void:
	_sm.set_state(States.HARVESTING)
	_crab.harvest_morsel(delta, morsel)


func _stop_harvesting() -> void:
	_crab.stop_harvest()
	_sm.unset_state(States.HARVESTING)


func _want_morsel(morsel: Morsel) -> bool:
	match morsel.mat_type:
		Morsel.MATERIAL_TYPE.IRON:
			return _want_iron()
		Morsel.MATERIAL_TYPE.COBALT:
			return _want_cobalt()
		Morsel.MATERIAL_TYPE.SILICON:
			return _want_silicon()
		_:
			return false


func _want_iron() -> bool:
	return _crab._carried_resources.iron < _crab.ironTarget


func _want_cobalt() -> bool:
	return _crab._carried_resources.cobalt < _crab.cobaltTarget


func _want_water() -> bool:
	return _crab._carried_resources.water < _crab.waterTarget


func _want_silicon() -> bool:
	return _crab._carried_resources.silicon < _crab.siliconTarget


func _find_visible_morsels() -> Array:
	var hits: Array
	for direction in _vision_ray_directions:
		var ray_query = PhysicsRayQueryParameters2D.create(_crab.position, _crab.position + direction * _vision_distance)
		ray_query.exclude = [_crab]
		var hit = _crab.get_world_2d().direct_space_state.intersect_ray(ray_query)
		if !hit.is_empty(): hits.push_back(hit)
	
	return (hits
		.map(func(hit) -> Node: return hit.collider)
		.map(func(body) -> Morsel: return body as Morsel)
		.filter(func(body) -> bool: return body != null)
	)


func _find_visible_morsels_by_distance() -> Array:
	var visible_morsels: Array = _find_visible_morsels()
	visible_morsels.sort_custom(func(a, b) -> bool:
		var a_distance: float = (a.position - _crab.position).length()
		var b_distance: float = (b.position - _crab.position).length()
		return a_distance < b_distance
	)
	return visible_morsels


func _create_wander_timer() -> void:
	_wander_timer = Timer.new()
	_wander_timer.one_shot = true
	add_child(_wander_timer)
