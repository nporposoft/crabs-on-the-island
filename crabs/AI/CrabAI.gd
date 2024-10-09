class_name CrabAI

extends Node


@onready var _crab: Crab = get_parent()
@onready var _island: Map = $"/root/Game/IslandV1"

@export var _vision_distance: float = 500.0
@export var _vision_check_delay: float = 0.25

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
var _vision_timer: Timer
var _visible_resources: Array

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
	_create_vision_timer()


# CrabAI runs in physics process b/c it uses 2D raycasting for vision
func _physics_process(delta: float) -> void:
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
	return false


func _continue_attack_routine(delta: float) -> bool:
	if _attack_target == null: return false
	
	_attack_crab(delta, _attack_target)
	return true


func _reproduce_routine(delta: float) -> bool:
	if _crab.has_reproduction_resources():
		_clear_states()

		if _crab.can_reproduce(): _reproduce(delta)
		else: _sm.set_state(States.CHARGING_BATTERY)
		return true
	return false


func _harvest_routine(delta: float) -> bool:
	if _vision_timer.is_stopped():
		_vision_timer.start()
		_visible_resources = _find_visible_resources()
	
	for resource: Dictionary in _visible_resources:
		if resource.object == null: continue
		if !_want_resource(resource): continue
		
		_clear_states()
		
		if _can_reach_resource(resource): _harvest_resource(delta, resource)
		else:
			_clear_states()
			_move_toward_resource(resource)
		return true
	
	return false


func _crab_harvest_routine(delta: float) -> bool:
	if _crab.has_reproduction_resources(): return false
	if !_crab.has_cobalt_target(): return false
	
	var nearby_crabs: Array = _get_nearby_crabs()
	for crab in nearby_crabs:
		if _want_to_attack_crab(crab):
			_attack_crab(delta, crab)
			return true
	return false


func _wander_routine() -> void:
	_stop_harvesting() # TODO: would be nice if the Crab state machine handled this
	if _sm.has_state(States.WANDERING):
		if _time_to_idle(): _start_idling()
		else: _keep_wandering()
	else:
		if _time_to_wander(): _start_wandering()


func _sleep() -> void:
	_clear_states()
	_sm.set_state(States.SLEEPING)


func _out_of_battery() -> bool:
	return _crab._sm.has_state(Crab.States.OUT_OF_BATTERY)


func _clear_states() -> void:
	_sm.unset_all_states()
	_stop_harvesting() # TODO: would be nice if the Crab state machine handled this


func _start_wandering() -> void:
	_wander_direction = Util.random_direction()
	_sm.set_state(States.WANDERING)
	_sm.unset_state(States.IDLING)
	_start_wander_timer()


func _start_idling() -> void:
	_sm.unset_state(States.WANDERING)
	_sm.set_state(States.IDLING)
	_crab.move(Vector2.ZERO) # TODO: would be nice if the Crab state machine handled this
	_start_idle_timer()


func _reproduce(delta: float) -> void:
	_sm.set_state(States.REPRODUCING)
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


func _move_toward_resource(resource: Dictionary) -> void:
	_sm.set_state(States.MOVING_TO_RESOURCE)
	_move_toward_point(resource.position)


func _move_toward_point(point: Vector2) -> void:
	var direction: Vector2 = point - _crab.position
	_crab.move(direction)


func _harvest_resource(delta: float, resource: Dictionary) -> void:
	_sm.set_state(States.HARVESTING)
	var morsel: Morsel = resource.object as Morsel
	if morsel != null:
		_crab.harvest_morsel(delta, morsel)
	elif resource.object == _island.WaterArea:
		_crab.harvest_water(delta)
	elif resource.object == _island.SandArea:
		_crab.harvest_sand(delta)


func _harvest_morsel(delta: float, morsel: Morsel) -> void:
	_sm.set_state(States.HARVESTING)
	_crab.harvest_morsel(delta, morsel)


func _want_to_attack_crab(crab: Crab) -> bool:
	return (
		(crab.will_drop_iron() && _want_iron()) ||
		(crab.will_drop_silicon() && _want_silicon())
	)


func _get_nearby_crabs() -> Array:
	return (
		_crab.get_nearby_crabs()
		.filter(func(crab: Crab) -> bool: return crab != _crab)
	)


func _can_reach_crab(crab: Crab) -> bool:
	return _crab.get_nearby_crabs().has(crab)


func _attack_crab(delta: float, crab: Crab) -> void:
	_sm.set_state(States.ATTACKING)
	if _can_reach_crab(crab):
		_crab.attackCrab(crab, delta)
	else:
		_move_toward_point(crab.position)


func _stop_harvesting() -> void:
	_crab.stop_harvest()
	_sm.unset_state(States.HARVESTING)


func _want_resource(resource: Dictionary) -> bool:
	var morsel: Morsel = resource.object as Morsel
	if morsel != null:
		return _want_morsel(morsel)
	if resource.object == _island.WaterArea:
		return _want_water()
	if resource.object == _island.SandArea:
		return _want_silicon()
	return false


func _can_reach_resource(resource: Dictionary) -> bool:
	var morsel: Morsel = resource.object as Morsel
	if morsel != null:
		return _crab.can_reach_morsel(morsel)
	if resource.object == _island.WaterArea:
		return _island.WaterArea.get_overlapping_bodies().has(_crab)
	if resource.object == _island.SandArea:
		return _island.SandArea.get_overlapping_bodies().has(_crab)
	return false


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


# Finds all resources within visible range (_vision_distance) using raycasts in the configured directions (_vision_ray_directions).
# Returns an array of Dictionaries; one for each visible resource.
# The dictionary structure is:
# {
#   "position": Vector2
#   "object": Morsel | Area2D
#   "distance": float
# }
# The array is sorted by distance in ascending order
func _find_visible_resources() -> Array:
	var resources: Array = (
		_detect_objects_with_rays()
		.map(func(hit) -> Dictionary:
		return {
			"position": hit.position,
			"object": hit.collider,
			"distance": (hit.position - _crab.position).length()
		}
		)
		.filter(func(hit) -> bool:
		if hit.object == _island.SandArea: return true
		if hit.object == _island.WaterArea: return true
		var morsel: Morsel = hit.object as Morsel
		if morsel != null: return true
		return false
		)
	)
	resources.sort_custom(func(a, b) -> bool: return a.distance < b.distance)
	return resources


func _detect_objects_with_rays() -> Array:
	var hits: Array
	for direction in _vision_ray_directions:
		var ray_query = PhysicsRayQueryParameters2D.create(_crab.position, _crab.position + direction * _vision_distance)
		ray_query.exclude = [_crab]
		ray_query.collide_with_areas = true
		var hit = _crab.get_world_2d().direct_space_state.intersect_ray(ray_query)
		if !hit.is_empty(): hits.push_back(hit)
	return hits


func _create_wander_timer() -> void:
	_wander_timer = Timer.new()
	_wander_timer.one_shot = true
	add_child(_wander_timer)


func _create_vision_timer() -> void:
	_vision_timer = Timer.new()
	_vision_timer.one_shot = true
	_vision_timer.wait_time = _vision_check_delay
	add_child(_vision_timer)
