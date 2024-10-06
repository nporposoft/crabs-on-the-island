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
	HARVESTING,
	REPRODUCING,
	CHARGING_BATTERY,
	SLEEPING
}


func _ready() -> void:
	_island = get_parent()
	_crab = $Crab
	_create_wander_timer()


# CrabAI runs in physics process b/c it uses 2D raycasting for obstacle detection
func _physics_process(delta: float) -> void:
	if _crab._sm.has_state(Crab.States.OUT_OF_BATTERY):
		_sm.unset_all_states()
		_stop_harvesting() # TODO: would be nice if the Crab state machine handled this
		_sm.set_state(States.SLEEPING)
		return
	
	if _crab.has_reproduction_resources():
		_sm.unset_all_states()
		_stop_harvesting() # TODO: would be nice if the Crab state machine handled this

		if _crab.can_reproduce():
			_sm.set_state(States.REPRODUCING)
			_crab.auto_reproduce()
		else:
			_sm.set_state(States.CHARGING_BATTERY)
		return
	
	var visibleResources: Array = _find_visible_resources()
	for resource: Dictionary in visibleResources:
		if !_want_resource(resource): continue
		
		_sm.unset_all_states()
		_crab.move(Vector2.ZERO) # TODO: would be nice if the Crab state machine handled this
		
		if _can_reach_resource(resource): _harvest_resource(delta, resource)
		else:
			_stop_harvesting() # TODO: would be nice if the Crab state machine handled this 
			_move_toward_resource(resource)
		return
	
	_stop_harvesting() # TODO: would be nice if the Crab state machine handled this
	
	if _sm.has_state(States.WANDERING):
		if _time_to_idle(): _start_idling()
		else: _keep_wandering()
	else:
		if _time_to_wander(): _start_wandering()


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
	var direction: Vector2 = resource.position - _crab.position
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
	var hits: Array
	for direction in _vision_ray_directions:
		var ray_query = PhysicsRayQueryParameters2D.create(_crab.position, _crab.position + direction * _vision_distance)
		ray_query.exclude = [_crab]
		ray_query.collide_with_areas = true
		var hit = _crab.get_world_2d().direct_space_state.intersect_ray(ray_query)
		if !hit.is_empty(): hits.push_back(hit)
	
	var resources: Array = (hits
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
